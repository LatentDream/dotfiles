/**
 * Clean UI Extension
 *
 * Header: completely blank (removes logo, version, help bar, extensions section).
 * Footer: single line — left: git-relative path | right: tokens + model
 *
 * Git path format: "my-repo/relative/path/from/repo/root"
 * Falls back to "~/shortened/absolute/path" when not in a git repo.
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execSync } from "child_process";
import { homedir } from "os";
import * as path from "path";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Shorten an absolute path to ~/... */
function shortenHome(p: string): string {
	const home = homedir();
	return p.startsWith(home) ? `~${p.slice(home.length)}` : p;
}

/**
 * Given a cwd, return "repo-name/relative/path" if inside a git repo,
 * otherwise return the home-shortened absolute path.
 */
function gitRelativePath(cwd: string): string {
	try {
		// Find the git root
		const gitRoot = execSync("git rev-parse --show-toplevel", {
			cwd,
			stdio: ["pipe", "pipe", "pipe"],
			encoding: "utf8",
		}).trim();

		const repoName = path.basename(gitRoot);
		const rel = path.relative(gitRoot, cwd);
		return rel ? `${repoName}/${rel}` : repoName;
	} catch {
		// Not a git repo — fall back to ~/... form
		return shortenHome(cwd);
	}
}

/** Format a token count as e.g. "1.2k" or "850" */
function fmtTokens(n: number): string {
	return n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`;
}

// ---------------------------------------------------------------------------
// Extension entry point
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;

		// ── Header: completely empty ──────────────────────────────────────────
		ctx.ui.setHeader((_tui, _theme) => ({
			render(_width: number): string[] {
				return [];
			},
			invalidate() {},
		}));

		// ── Footer: path left | tokens + model right ──────────────────────────
		ctx.ui.setFooter((tui, theme, footerData) => {
			// Re-render whenever the git branch changes (branch watcher fires on
			// HEAD changes which also covers repo detection changes).
			const unsub = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: unsub,
				invalidate() {},

				render(width: number): string[] {
					// ── Left: git-relative (or home-shortened) path ──────────────
					const displayPath = gitRelativePath(ctx.cwd);
					const left = theme.fg("muted", displayPath);

					// ── Right: ↑in ↓out $cost  model-id ────────────────────────
					let inputTokens = 0;
					let outputTokens = 0;
					let totalCost = 0;

					for (const entry of ctx.sessionManager.getBranch()) {
						if (
							entry.type === "message" &&
							entry.message.role === "assistant"
						) {
							const m = entry.message as AssistantMessage;
							inputTokens += m.usage.input;
							outputTokens += m.usage.output;
							totalCost += m.usage.cost.total;
						}
					}

					const modelId = ctx.model?.id ?? "no model";

					const tokenPart = theme.fg(
						"dim",
						`↑${fmtTokens(inputTokens)} ↓${fmtTokens(outputTokens)} $${totalCost.toFixed(3)}`
					);
					const modelPart = theme.fg("muted", modelId);
					const right = `${tokenPart}  ${modelPart}`;

					// ── Compose: left … right ────────────────────────────────────
					const gap = Math.max(1, width - visibleWidth(left) - visibleWidth(right));
					const line = left + " ".repeat(gap) + right;
					return [truncateToWidth(line, width)];
				},
			};
		});
	});
}
