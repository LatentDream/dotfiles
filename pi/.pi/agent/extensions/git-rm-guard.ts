/**
 * Git RM Guard Extension
 *
 * Intercepts every `rm` bash command and checks whether any of the targeted
 * files are UNTRACKED by git.  Untracked files can't be recovered, so the
 * user is prompted before they are deleted.  Tracked files are always allowed
 * through silently — git has them covered.
 *
 * Detection strategy
 * ------------------
 * The extension parses the raw shell command with a lightweight regex to
 * extract the non-flag arguments (the paths).  For each path it runs
 *   git ls-files --error-unmatch <path>
 * in the directory where the bash tool would run (`ctx.cwd`).  Any path
 * for which that command exits non-zero (or git is unavailable) is considered
 * untracked and therefore dangerous to delete.
 *
 * Edge cases handled
 * ------------------
 * - Flags (-r, -f, -rf, --force, -i, …) are stripped before path parsing.
 * - Globs are left to the shell; for glob arguments we run `git ls-files`
 *   without --error-unmatch and treat no output as "untracked".
 * - If no UI is available (print / RPC mode) the command is blocked when
 *   untracked files are found.
 * - If `git` is not available or the path is not inside a git repo, the
 *   file is treated as untracked (safe default: prompt).
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { DynamicBorder } from "@mariozechner/pi-coding-agent";
import { Container, Text, matchesKey, Key } from "@mariozechner/pi-tui";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Parse path arguments out of an `rm` command string.
 *
 * We do a best-effort split: treat space-separated tokens that do NOT start
 * with `-` as paths, ignoring shell quoting complexities for the common case.
 * Quoted paths like `rm "my file.txt"` are handled by collapsing adjacent
 * quoted segments.
 */
function parseRmPaths(command: string): string[] {
	// Strip the leading `rm` token and any options
	const tokens = splitTokens(command);

	// Find the position of the first `rm` invocation in the token list and
	// skip everything up to and including it.
	const rmIdx = tokens.findIndex((t) => t === "rm");
	if (rmIdx === -1) return [];

	const afterRm = tokens.slice(rmIdx + 1);

	// Collect non-flag tokens as paths; stop at `--` (end-of-options sentinel)
	const paths: string[] = [];
	let endOfOptions = false;
	for (const token of afterRm) {
		if (token === "--") {
			endOfOptions = true;
			continue;
		}
		if (!endOfOptions && token.startsWith("-")) continue;
		paths.push(token);
	}
	return paths;
}

/**
 * Naively split a shell command into tokens, respecting single and double
 * quotes enough to handle the most common cases.
 */
function splitTokens(command: string): string[] {
	const tokens: string[] = [];
	let current = "";
	let inSingle = false;
	let inDouble = false;

	for (let i = 0; i < command.length; i++) {
		const ch = command[i];
		if (ch === "'" && !inDouble) {
			inSingle = !inSingle;
		} else if (ch === '"' && !inSingle) {
			inDouble = !inDouble;
		} else if (ch === " " && !inSingle && !inDouble) {
			if (current) {
				tokens.push(current);
				current = "";
			}
		} else {
			current += ch;
		}
	}
	if (current) tokens.push(current);
	return tokens;
}

/**
 * Returns the subset of `paths` that are NOT tracked by git.
 * Runs from `cwd`.  If git is unavailable or the path is outside a repo,
 * the file is conservatively treated as untracked.
 */
async function gitUntrackedPaths(paths: string[], cwd: string): Promise<string[]> {
	if (paths.length === 0) return [];

	const untracked: string[] = [];

	for (const p of paths) {
		const isGlob = p.includes("*") || p.includes("?") || p.includes("[");
		try {
			if (isGlob) {
				// For globs: if git lists no files, nothing under this glob is tracked
				const { stdout } = await execFileAsync("git", ["ls-files", p], { cwd });
				if (stdout.trim().length === 0) untracked.push(p);
			} else {
				// --error-unmatch exits non-zero when the file is NOT tracked
				await execFileAsync("git", ["ls-files", "--error-unmatch", p], { cwd });
				// exit 0 → tracked → safe, do nothing
			}
		} catch {
			// Non-zero exit or git unavailable → treat as untracked (prompt)
			untracked.push(p);
		}
	}

	return untracked;
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined;

		const command = event.input.command as string;

		// Quick pre-filter: only proceed if the command contains `rm`
		if (!/\brm\b/.test(command)) return undefined;

		const paths = parseRmPaths(command);
		if (paths.length === 0) return undefined;

		const untrackedFiles = await gitUntrackedPaths(paths, ctx.cwd);
		if (untrackedFiles.length === 0) return undefined;

		// -----------------------------------------------------------------------
		// Untracked files are about to be deleted — they can't be recovered!
		// -----------------------------------------------------------------------
		if (!ctx.hasUI) {
			return {
				block: true,
				reason: `Blocked: attempted to rm untracked file(s): ${untrackedFiles.join(", ")}`,
			};
		}

		const fileList = untrackedFiles.map((f) => `  • ${f}`).join("\n");
		const displayCmd = command.length > 200 ? command.slice(0, 197) + "…" : command;
		const plural = untrackedFiles.length > 1;

		type Choice = "yes" | "no";

		const choice = await ctx.ui.custom<Choice | null>((tui, theme, _kb, done) => {
			const container = new Container();

			container.addChild(new DynamicBorder((s: string) => theme.fg("error", s)));
			container.addChild(new Text(theme.fg("error", theme.bold(`⚠️  Deleting UNTRACKED file${plural ? "s" : ""} (not recoverable via git)`)), 1, 0));
			container.addChild(new Text("", 0, 0));

			for (const line of displayCmd.split("\n")) {
				container.addChild(new Text(theme.fg("muted", "  " + line), 0, 0));
			}
			container.addChild(new Text("", 0, 0));

			const options: Array<{ label: string; value: Choice; color: Parameters<typeof theme.fg>[0] }> = [
				{ label: `[y] Yes, delete ${plural ? "them" : "it"}`, value: "yes", color: "error" },
				{ label: "[n] No, cancel", value: "no", color: "success" },
			];
			for (const opt of options) {
				container.addChild(new Text(theme.fg(opt.color, opt.label), 1, 0));
			}
			container.addChild(new DynamicBorder((s: string) => theme.fg("error", s)));

			return {
				render: (w: number) => container.render(w),
				invalidate: () => container.invalidate(),
				handleInput: (data: string) => {
					if (data === "y" || data === "Y") { done("yes"); return; }
					if (data === "n" || data === "N") { done("no"); return; }
					if (matchesKey(data, Key.escape)) { done("no"); return; }
					tui.requestRender();
				},
			};
		});

		if (!choice || choice === "no") {
			return { block: true, reason: "Blocked by user: untracked file deletion cancelled" };
		}

		return undefined; // Allow the command
	});
}
