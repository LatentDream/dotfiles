/**
 * Bash Green Flag Extension
 *
 * Intercepts every bash tool call the agent makes and checks it against a
 * list of pre-approved glob-style patterns stored in ~/.pi/bash-greenflag.json.
 *
 * If the command matches a green-flagged pattern it runs without interruption.
 * For compound commands (&&, ||, ;, |, newlines) EVERY sub-command must match.
 * Otherwise the user is presented with three choices:
 *   1. [y] Yes, run it          – let this specific command through
 *   2. [n] No, refuse            – block this command
 *   3. [g] Yes + add to green flag list – let through AND add a pattern to the green-flag list
 *                           (a second prompt lets the user refine the pattern;
 *                            Esc goes back to the 3-choice menu)
 *
 * When a command passes silently, the matched pattern is briefly shown in the
 * footer status line for 3 seconds.
 *
 * Pattern syntax (glob-style):
 *   *        matches any sequence of characters except /
 *   **       matches any sequence of characters including /
 *   ?        matches any single character
 *   [abc]    matches one of the characters listed
 *
 * Examples in bash-greenflag.json:
 *   ls**            → ls, ls -la, ls /some/path, ...
 *   git status**    → git status and any flags
 *   kubectl logs**  → kubectl logs with any arguments
 *
 * File location: ~/.pi/bash-greenflag.json
 *   { "patterns": ["ls**", "git status**", "kubectl logs**"] }
 *
 * Commands:
 *   /greenflag         – list all patterns
 *   /greenflag clear   – remove all patterns
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { homedir } from "node:os";
import type { ExtensionAPI, Theme } from "@mariozechner/pi-coding-agent";
import { DynamicBorder } from "@mariozechner/pi-coding-agent";
import { Container, Text, matchesKey, Key, truncateToWidth } from "@mariozechner/pi-tui";

// ─── Config helpers ──────────────────────────────────────────────────────────

const CONFIG_PATH = join(homedir(), ".pi", "bash-greenflag.json");

interface GreenFlagConfig {
	patterns: string[];
}

function loadConfig(): GreenFlagConfig {
	if (!existsSync(CONFIG_PATH)) return { patterns: [] };
	try {
		const raw = readFileSync(CONFIG_PATH, "utf-8");
		const parsed = JSON.parse(raw) as Partial<GreenFlagConfig>;
		return { patterns: Array.isArray(parsed.patterns) ? parsed.patterns : [] };
	} catch {
		return { patterns: [] };
	}
}

function saveConfig(config: GreenFlagConfig): void {
	const dir = dirname(CONFIG_PATH);
	if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
	writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2) + "\n", "utf-8");
}

// ─── Glob matching ───────────────────────────────────────────────────────────

/**
 * Convert a glob pattern to a RegExp.
 *   **  → .* (anything incl. /)
 *   *   → [^/]* (anything except /)
 *   ?   → . (one char)
 *   […] → character class (passed through)
 */
function globToRegex(pattern: string): RegExp {
	let re = "";
	let i = 0;
	while (i < pattern.length) {
		const ch = pattern[i];
		if (ch === "*" && pattern[i + 1] === "*") {
			re += ".*";
			i += 2;
		} else if (ch === "*") {
			re += "[^/]*";
			i++;
		} else if (ch === "?") {
			re += ".";
			i++;
		} else if (ch === "[") {
			const end = pattern.indexOf("]", i);
			if (end === -1) { re += "\\["; i++; }
			else { re += pattern.slice(i, end + 1); i = end + 1; }
		} else {
			re += ch.replace(/[.+^${}()|\\]/g, "\\$&");
			i++;
		}
	}
	return new RegExp(`^${re}$`);
}

function matchesPattern(command: string, pattern: string): boolean {
	const cmd = command.trim();
	const pat = pattern.trim();
	if (!pat) return false;
	try { return globToRegex(pat).test(cmd); }
	catch { return false; }
}

/**
 * Split a compound command into individual sub-commands.
 * Splits on: newlines, &&, ||, ;, |  — but NOT inside single or double quotes.
 */
function splitSubCommands(command: string): string[] {
	const parts: string[] = [];
	let current = "";
	let inSingle = false;
	let inDouble = false;
	let i = 0;

	while (i < command.length) {
		const ch = command[i]!;

		// Track quote state (handle backslash escape inside double quotes)
		if (ch === "'" && !inDouble) {
			inSingle = !inSingle;
			current += ch;
			i++;
			continue;
		}
		if (ch === '"' && !inSingle) {
			inDouble = !inDouble;
			current += ch;
			i++;
			continue;
		}
		if (ch === "\\" && (inDouble || inSingle)) {
			// escaped character — consume both and keep going
			current += ch + (command[i + 1] ?? "");
			i += 2;
			continue;
		}

		if (!inSingle && !inDouble) {
			// newline always splits
			if (ch === "\n") {
				parts.push(current.trim());
				current = "";
				i++;
				continue;
			}
			// ; splits
			if (ch === ";") {
				parts.push(current.trim());
				current = "";
				i++;
				continue;
			}
			// && or || split
			if ((ch === "&" && command[i + 1] === "&") || (ch === "|" && command[i + 1] === "|")) {
				parts.push(current.trim());
				current = "";
				i += 2;
				continue;
			}
			// single | (pipe) splits — but only when not preceded by a backslash
			if (ch === "|") {
				parts.push(current.trim());
				current = "";
				i++;
				continue;
			}
		}

		current += ch;
		i++;
	}

	if (current.trim()) parts.push(current.trim());
	return parts.filter(Boolean);
}

/**
 * If every sub-command of `command` is green-flagged, return the pattern that
 * matched the first sub-command (representative label for the status display).
 * Otherwise return undefined.
 */
function findMatchingPattern(command: string, patterns: string[]): string | undefined {
	const parts = splitSubCommands(command);
	if (parts.length === 0) return undefined;
	for (const part of parts) {
		if (!patterns.some((p) => matchesPattern(part, p))) return undefined;
	}
	return patterns.find((p) => matchesPattern(parts[0]!, p));
}

// ─── Pattern input component ─────────────────────────────────────────────────

/**
 * A minimal single-line text editor component.
 * Supports: printable chars, backspace/delete, ←/→, ctrl+a/e/w, enter, esc.
 */
class PatternInput {
	private buf: string[] = [];
	private cursor = 0;
	private _cachedWidth?: number;
	private _cachedLines?: string[];
	theme: Theme;

	onSubmit?: (value: string) => void;
	onCancel?: () => void;

	constructor(initial: string, theme: Theme) {
		this.buf = [...initial];
		this.cursor = this.buf.length;
		this.theme = theme;
	}

	getValue(): string { return this.buf.join(""); }

	handleInput(data: string): void {
		this._cachedLines = undefined;
		if (matchesKey(data, Key.enter)) { this.onSubmit?.(this.getValue()); return; }
		if (matchesKey(data, Key.escape)) { this.onCancel?.(); return; }
		if (matchesKey(data, Key.left) || data === "\x1b[D") { if (this.cursor > 0) this.cursor--; return; }
		if (matchesKey(data, Key.right) || data === "\x1b[C") { if (this.cursor < this.buf.length) this.cursor++; return; }
		if (matchesKey(data, Key.home) || data === "\x01") { this.cursor = 0; return; }
		if (matchesKey(data, Key.end) || data === "\x05") { this.cursor = this.buf.length; return; }
		if (matchesKey(data, Key.backspace) || data === "\x7f" || data === "\x08") {
			if (this.cursor > 0) { this.buf.splice(this.cursor - 1, 1); this.cursor--; }
			return;
		}
		if (matchesKey(data, Key.delete)) {
			if (this.cursor < this.buf.length) this.buf.splice(this.cursor, 1);
			return;
		}
		if (data === "\x17") { // ctrl+w — delete word before cursor
			while (this.cursor > 0 && this.buf[this.cursor - 1] === " ") { this.buf.splice(this.cursor - 1, 1); this.cursor--; }
			while (this.cursor > 0 && this.buf[this.cursor - 1] !== " ") { this.buf.splice(this.cursor - 1, 1); this.cursor--; }
			return;
		}
		if (data.length === 1 && data.charCodeAt(0) >= 32) {
			this.buf.splice(this.cursor, 0, data);
			this.cursor++;
		}
	}

	render(width: number): string[] {
		if (this._cachedLines && this._cachedWidth === width) return this._cachedLines;
		const value = this.getValue();
		const before = value.slice(0, this.cursor);
		const atCursor = value[this.cursor] ?? " ";
		const after = value.slice(this.cursor + 1);
		const rawLine = `▸ ${before}${this.theme.bg("selectedBg", atCursor)}${after}`;
		this._cachedLines = [truncateToWidth(rawLine, width)];
		this._cachedWidth = width;
		return this._cachedLines;
	}

	invalidate(): void {
		this._cachedWidth = undefined;
		this._cachedLines = undefined;
	}
}

// ─── Extension entry point ───────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined;
		if (!ctx.hasUI) return undefined; // non-interactive: let commands through

		const command = (event.input as { command: string }).command;

		// rm commands are handled by the git-rm-guard extension — skip greenflag
		if (/\brm\b/.test(command)) return undefined;

		// Read fresh from disk every time so edits take effect without /reload
		const patterns = loadConfig().patterns;

		// Fix 1: compound commands — every sub-command must be green-flagged
		const matchedPattern = findMatchingPattern(command, patterns);
		if (matchedPattern !== undefined) {
			// Fix 4: briefly show which pattern matched in the footer
			ctx.ui.setStatus("greenflag", ctx.ui.theme.fg("muted", `✓ greenflag: ${matchedPattern}`));
			setTimeout(() => ctx.ui.setStatus("greenflag", undefined), 3000);
			return undefined;
		}

		// Truncate long commands for display
		const displayCmd = command.length > 200 ? command.slice(0, 197) + "…" : command;

		type Choice = "accept" | "refuse" | "add";

		// Fix 6: loop so Esc in the pattern editor returns to the approval menu
		while (true) {
			const choice = await ctx.ui.custom<Choice | null>((tui, theme, _kb, done) => {
				const container = new Container();

				container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));
				container.addChild(new Text(theme.fg("accent", theme.bold("⚑ Bash command requires approval")), 1, 0));
				container.addChild(new Text("", 0, 0));

				for (const line of displayCmd.split("\n")) {
					container.addChild(new Text(theme.fg("muted", "  " + line), 0, 0));
				}
				container.addChild(new Text("", 0, 0));

				const options: Array<{ label: string; value: Choice; color: Parameters<typeof theme.fg>[0] }> = [
					{ label: "[y] Yes, run it", value: "accept", color: "success" },
					{ label: "[n] No, refuse", value: "refuse", color: "error" },
					{ label: "[g] Yes + add to green flag list", value: "add", color: "muted" },
				];
				for (const opt of options) {
					container.addChild(new Text(theme.fg(opt.color, opt.label), 1, 0));
				}
				container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));

				return {
					render: (w: number) => container.render(w),
					invalidate: () => container.invalidate(),
					handleInput: (data: string) => {
						if (data === "y" || data === "Y") { done("accept"); return; }
						if (data === "n" || data === "N") { done("refuse"); return; }
						if (data === "g" || data === "G") { done("add"); return; }
						if (matchesKey(data, Key.escape)) { done("refuse"); return; }
						tui.requestRender();
					},
				};
			});

			if (!choice || choice === "refuse") {
				return { block: true, reason: "Blocked by user (bash-greenflag)" };
			}
			if (choice === "accept") {
				return undefined;
			}

			// choice === "add" ── pattern editor ─────────────────────────────
			const firstWord = command.trim().split(/\s+/)[0] ?? command.trim();
			const defaultPattern = firstWord + "**";

			const HELP_LINES = [
				"  Pattern syntax:",
				"   *   → any chars except /   e.g. ls* or git status*",
				"   **  → any chars incl. /    e.g. kubectl logs**",
				"   ?   → any single char",
				"  Enter to confirm • Esc to go back",
			];

			const patternOrNull = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
				const container = new Container();

				container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));
				container.addChild(new Text(theme.fg("accent", theme.bold("Add to green flag list")), 1, 0));
				container.addChild(new Text("", 0, 0));

				// Fix 6: show the command for reference while editing the pattern
				container.addChild(new Text(theme.fg("dim", "  Command:"), 0, 0));
				for (const line of displayCmd.split("\n")) {
					container.addChild(new Text(theme.fg("muted", "    " + line), 0, 0));
				}
				container.addChild(new Text("", 0, 0));

				for (const line of HELP_LINES) {
					container.addChild(new Text(theme.fg("dim", line), 0, 0));
				}
				container.addChild(new Text("", 0, 0));
				container.addChild(new Text(theme.fg("muted", "  Pattern:"), 0, 0));

				const input = new PatternInput(defaultPattern, theme);
				input.onSubmit = (val) => done(val.trim() || null);
				input.onCancel = () => done("__back__" as any); // sentinel → loop back

				container.addChild({
					render: (w: number) => input.render(w),
					invalidate: () => { input.theme = theme; input.invalidate(); },
				} as any);
				container.addChild(new Text("", 0, 0));
				container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));

				return {
					render: (w: number) => container.render(w),
					invalidate: () => container.invalidate(),
					handleInput: (data: string) => { input.handleInput(data); tui.requestRender(); },
				};
			});

			// Esc in pattern editor → go back to approval menu
			if (patternOrNull === ("__back__" as any) || patternOrNull === null) continue;

			const config = loadConfig();
			if (!config.patterns.includes(patternOrNull)) {
				config.patterns.push(patternOrNull);
				saveConfig(config);
				ctx.ui.notify(`✓ Green-flagged: "${patternOrNull}"`, "info");
			} else {
				ctx.ui.notify(`Pattern already exists: "${patternOrNull}"`, "info");
			}
			return undefined; // let the command through
		}
	});

	pi.registerCommand("greenflag", {
		description: "View or clear bash green-flag patterns",
		handler: async (args, ctx) => {
			const config = loadConfig();

			if (args?.trim() === "clear") {
				config.patterns = [];
				saveConfig(config);
				ctx.ui.notify("Green-flag list cleared", "info");
				return;
			}

			if (config.patterns.length === 0) {
				ctx.ui.notify("No green-flagged patterns yet. Run a bash command and choose 'Accept + add'.", "info");
				return;
			}

			const lines = [
				`Green-flagged patterns (${CONFIG_PATH}):`,
				...config.patterns.map((p, i) => `  ${i + 1}. ${p}`),
				"",
				"Use /greenflag clear to remove all patterns.",
			];
			ctx.ui.notify(lines.join("\n"), "info");
		},
	});
}
