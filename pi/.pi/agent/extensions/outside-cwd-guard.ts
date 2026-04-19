/**
 * Outside-CWD Guard Extension
 *
 * Prompts for confirmation before the agent writes or edits a file that lives
 * outside the directory pi was started from (ctx.cwd).
 *
 * Covered tools:
 *   - write   – checked via `input.path`
 *   - edit    – checked via `input.path`
 *
 * When the resolved target path is not inside ctx.cwd (or any of its
 * descendants), the user is shown an Accept / Refuse dialog.
 *
 * Non-interactive mode (print / RPC / JSON) blocks automatically – there is
 * no terminal to prompt.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { resolve, relative, normalize } from "node:path";
import { realpath } from "node:fs/promises";

// ── helpers ──────────────────────────────────────────────────────────────────

/**
 * Strip a leading `@` that some models add to path arguments.
 */
function stripAt(p: string): string {
	return p.startsWith("@") ? p.slice(1) : p;
}

/**
 * Resolve `inputPath` relative to `cwd`, then check whether it is inside
 * `cwd`.  We try to canonicalise via `realpath` so that symlinks don't fool
 * the check, but we fall back gracefully when the file doesn't exist yet
 * (write to a new file).
 *
 * Returns `true` when the path IS inside cwd (safe, no prompt needed).
 */
async function isInsideCwd(inputPath: string, cwd: string): Promise<boolean> {
	const stripped = stripAt(inputPath);

	// Resolve against cwd so relative paths work correctly
	const absolute = resolve(cwd, stripped);

	// Try to canonicalise (resolves symlinks).  If the file doesn't exist yet
	// we fall back to the lexically-resolved path.
	let canonical: string;
	try {
		canonical = await realpath(absolute);
	} catch {
		canonical = normalize(absolute);
	}

	// Also canonicalise cwd itself
	let canonicalCwd: string;
	try {
		canonicalCwd = await realpath(cwd);
	} catch {
		canonicalCwd = normalize(cwd);
	}

	const rel = relative(canonicalCwd, canonical);

	// relative() returns a path starting with ".." when canonical is outside cwd.
	// An empty string means they are the same directory (also inside).
	// An absolute path (which relative() never produces) would be a bug, so no
	// extra guard is needed beyond the ".." check.
	return rel === "" || (!rel.startsWith("..") && !rel.startsWith("/"));
}

// ── extension ────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		// Only care about file-mutation tools
		if (event.toolName !== "write" && event.toolName !== "edit") {
			return undefined;
		}

		const rawPath = (event.input as { path?: string }).path;
		if (!rawPath || typeof rawPath !== "string") return undefined;

		const inside = await isInsideCwd(rawPath, ctx.cwd);
		if (inside) return undefined; // Nothing to do

		// ── Outside cwd ──────────────────────────────────────────────────────
		const resolvedDisplay = resolve(ctx.cwd, stripAt(rawPath));
		const toolLabel = event.toolName === "write" ? "write" : "edit";
		const title =
			`⚠️  Agent wants to ${toolLabel} a file OUTSIDE the current working directory:\n\n` +
			`  Path : ${resolvedDisplay}\n` +
			`  CWD  : ${ctx.cwd}\n\n` +
			`Allow this operation?`;

		if (!ctx.hasUI) {
			// Non-interactive mode: block by default (no way to ask)
			return {
				block: true,
				reason: `Blocked: ${toolLabel} to "${resolvedDisplay}" is outside the working directory "${ctx.cwd}". ` +
					`Run pi interactively to approve out-of-cwd writes.`,
			};
		}

		const choice = await ctx.ui.select(title, ["Yes, allow this once", "No, block it"]);

		if (choice !== "Yes, allow this once") {
			ctx.ui.notify(`Blocked ${toolLabel} to ${resolvedDisplay}`, "warning");
			return {
				block: true,
				reason: `Blocked by user: ${toolLabel} to "${resolvedDisplay}" is outside the working directory.`,
			};
		}

		ctx.ui.notify(`Allowed ${toolLabel} to ${resolvedDisplay}`, "info");
		return undefined; // Let it through
	});
}
