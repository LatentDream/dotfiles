/**
 * Plan Mode Toggle Extension
 *
 * Toggles between "default" (full access) and "plan" (readonly) mode.
 * Run /plan to switch between modes.
 *
 * In Plan mode:
 * - File-mutating tools (write, edit) are disabled
 * - The agent is informed it is in plan/readonly mode and must not modify files
 * - A status indicator is shown in the footer
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

// ── Safe-command gating ───────────────────────────────────────────────────────

const DESTRUCTIVE_PATTERNS = [
	/\brm\b/i,
	/\brmdir\b/i,
	/\bmv\b/i,
	/\bcp\b/i,
	/\bmkdir\b/i,
	/\btouch\b/i,
	/\bchmod\b/i,
	/\bchown\b/i,
	/\bchgrp\b/i,
	/\bln\b/i,
	/\btee\b/i,
	/\btruncate\b/i,
	/\bdd\b/i,
	/\bshred\b/i,
	/(^|[^<])>(?!>)/, // single redirect >
	/>>/, // append redirect >>
	/\bnpm\s+(install|uninstall|update|ci|link|publish)/i,
	/\byarn\s+(add|remove|install|publish)/i,
	/\bpnpm\s+(add|remove|install|publish)/i,
	/\bpip\s+(install|uninstall)/i,
	/\bapt(-get)?\s+(install|remove|purge|update|upgrade)/i,
	/\bbrew\s+(install|uninstall|upgrade)/i,
	/\bgit\s+(add|commit|push|pull|merge|rebase|reset|checkout|branch\s+-[dD]|stash|cherry-pick|revert|tag|init|clone)/i,
	/\bsudo\b/i,
	/\bsu\b/i,
	/\bkill\b/i,
	/\bpkill\b/i,
	/\bkillall\b/i,
	/\breboot\b/i,
	/\bshutdown\b/i,
	/\bsystemctl\s+(start|stop|restart|enable|disable)/i,
	/\bservice\s+\S+\s+(start|stop|restart)/i,
	/\b(vim?|nano|emacs|code|subl)\b/i,
];

const SAFE_PATTERNS = [
	/^\s*cat\b/,
	/^\s*head\b/,
	/^\s*tail\b/,
	/^\s*less\b/,
	/^\s*more\b/,
	/^\s*grep\b/,
	/^\s*find\b/,
	/^\s*ls\b/,
	/^\s*pwd\b/,
	/^\s*echo\b/,
	/^\s*printf\b/,
	/^\s*wc\b/,
	/^\s*sort\b/,
	/^\s*uniq\b/,
	/^\s*diff\b/,
	/^\s*file\b/,
	/^\s*stat\b/,
	/^\s*du\b/,
	/^\s*df\b/,
	/^\s*tree\b/,
	/^\s*which\b/,
	/^\s*whereis\b/,
	/^\s*type\b/,
	/^\s*env\b/,
	/^\s*printenv\b/,
	/^\s*uname\b/,
	/^\s*whoami\b/,
	/^\s*id\b/,
	/^\s*date\b/,
	/^\s*cal\b/,
	/^\s*uptime\b/,
	/^\s*ps\b/,
	/^\s*top\b/,
	/^\s*htop\b/,
	/^\s*free\b/,
	/^\s*git\s+(status|log|diff|show|branch|remote|config\s+--get)/i,
	/^\s*git\s+ls-/i,
	/^\s*npm\s+(list|ls|view|info|search|outdated|audit)/i,
	/^\s*yarn\s+(list|info|why|audit)/i,
	/^\s*node\s+--version/i,
	/^\s*python\s+--version/i,
	/^\s*curl\s/i,
	/^\s*wget\s+-O\s*-/i,
	/^\s*jq\b/,
	/^\s*sed\s+-n/i,
	/^\s*awk\b/,
	/^\s*rg\b/,
	/^\s*fd\b/,
	/^\s*bat\b/,
	/^\s*eza\b/,
];

function isSafeCommand(command: string): boolean {
	const isDestructive = DESTRUCTIVE_PATTERNS.some((p) => p.test(command));
	const isSafe = SAFE_PATTERNS.some((p) => p.test(command));
	return !isDestructive && isSafe;
}

// ─────────────────────────────────────────────────────────────────────────────

const PLAN_MODE_TOOLS = ["read", "bash", "grep", "find", "ls"];
const DEFAULT_MODE_TOOLS = ["read", "bash", "edit", "write", "grep", "find", "ls"];

export default function planModeToggle(pi: ExtensionAPI): void {
	let planMode = false;

	// ── Helpers ──────────────────────────────────────────────────────────────

	function applyMode(ctx: ExtensionContext): void {
		if (planMode) {
			pi.setActiveTools(PLAN_MODE_TOOLS);
			ctx.ui.setStatus("plan-mode-toggle", ctx.ui.theme.fg("accent", "📋 PLAN (readonly)"));
		} else {
			pi.setActiveTools(DEFAULT_MODE_TOOLS);
			ctx.ui.setStatus("plan-mode-toggle", undefined);
		}
	}

	function toggle(ctx: ExtensionContext): void {
		planMode = !planMode;
		applyMode(ctx);
		ctx.ui.notify(
			planMode
				? "Switched to Plan (readonly) mode. Run /plan to return to Default."
				: "Switched to Default mode. Run /plan to enter Plan (readonly) mode.",
			"info",
		);
	}

	// ── Command: /plan ──────────────────────────────────────────────────────

	pi.registerCommand("plan", {
		description: "Toggle between Default and Plan (readonly) mode",
		handler: async (_args, ctx) => toggle(ctx),
	});

	// ── Block mutations in plan mode ──────────────────────────────────────────

	pi.on("tool_call", async (event) => {
		if (!planMode) return;

		// Block write/edit tools
		const mutatingTools = new Set(["write", "edit"]);
		if (mutatingTools.has(event.toolName)) {
			return {
				block: true,
				reason:
					`Plan mode (readonly): "${event.toolName}" is disabled. ` +
					"Switch to Default mode first (run /plan).",
			};
		}

		// Block unsafe bash commands
		if (event.toolName === "bash") {
			const command = (event.input as { command: string }).command;
			if (!isSafeCommand(command)) {
				return {
					block: true,
					reason:
						`Plan mode (readonly): bash command blocked (not on the read-only allowlist).\n` +
						`Command: ${command}\n` +
						"Switch to Default mode first (run /plan).",
				};
			}
		}
	});

	// ── Inject system-prompt context before every agent turn ─────────────────

	pi.on("before_agent_start", async (_event, ctx) => {
		if (!planMode) return;

		// Keep system prompt accurate about capabilities
		const extra =
			"\n\n---\n" +
			"**[PLAN / READONLY MODE ACTIVE]**\n" +
			"You are currently in **plan mode** (readonly). " +
			"You MUST NOT create, modify, or delete any files. " +
			"The `edit` and `write` tools are disabled and will be blocked if called.\n" +
			"Only use read-only tools: `read`, `bash` (read-only commands), `grep`, `find`, `ls`.\n" +
			"Describe what you would do; produce plans, analyses, and explanations instead of making changes.";

		return {
			systemPrompt: ctx.getSystemPrompt() + extra,
		};
	});

	// ── Restore mode on session resume ───────────────────────────────────────

	pi.on("session_start", async (_event, ctx) => {
		const entries = ctx.sessionManager.getEntries();

		// Find the most recent persisted state
		const stateEntry = entries
			.filter(
				(e: { type: string; customType?: string }) =>
					e.type === "custom" && e.customType === "plan-mode-toggle-state",
			)
			.pop() as { data?: { planMode: boolean } } | undefined;

		if (stateEntry?.data) {
			planMode = stateEntry.data.planMode ?? false;
		}

		applyMode(ctx);
	});

	// Persist mode on every agent end so session restores work correctly
	pi.on("agent_end", async () => {
		pi.appendEntry("plan-mode-toggle-state", { planMode });
	});
}
