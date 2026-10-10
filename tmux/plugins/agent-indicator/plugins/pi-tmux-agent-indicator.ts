import { execFile } from "node:child_process";
import { realpathSync } from "node:fs";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type AgentState = "off" | "running" | "needs-input" | "done";

const extensionFile = realpathSync(fileURLToPath(import.meta.url));
const stateScript = fileURLToPath(new URL("../scripts/agent-state.sh", `file://${extensionFile}`));

function report(args: string[]): Promise<void> {
	return new Promise((resolve) => {
		execFile(stateScript, ["--agent", "pi", ...args], () => resolve());
	});
}

function sessionArgs(ctx: ExtensionContext): string[] {
	const id = ctx.sessionManager.getSessionId();
	const name = ctx.sessionManager.getSessionName();
	return [
		...(id ? ["--session-id", id] : []),
		...(name ? ["--session-name", name] : []),
	];
}

export default function piTmuxAgentIndicator(pi: ExtensionAPI): void {
	let currentState: AgentState = "off";
	let stateBeforePrompt: AgentState = "off";
	let promptDepth = 0;

	async function setState(state: AgentState, ctx?: ExtensionContext): Promise<void> {
		currentState = state;
		await report(["--state", state, ...(ctx ? sessionArgs(ctx) : [])]);
	}

	pi.on("session_start", async (_event, ctx) => {
		promptDepth = 0;
		stateBeforePrompt = "off";
		await setState("off");
		await report(sessionArgs(ctx));
	});

	pi.on("session_info_changed", async (_event, ctx) => {
		await report(sessionArgs(ctx));
	});

	pi.on("agent_start", async (_event, ctx) => {
		await setState("running", ctx);
	});

	pi.on("ui_prompt_start", async (_event, ctx) => {
		if (promptDepth === 0) stateBeforePrompt = currentState;
		promptDepth += 1;
		await setState("needs-input", ctx);
	});

	pi.on("ui_prompt_end", async (_event, ctx) => {
		promptDepth = Math.max(0, promptDepth - 1);
		if (promptDepth === 0) await setState(stateBeforePrompt, ctx);
	});

	// agent_settled is the final boundary after retries, compaction, and queued work.
	pi.on("agent_settled", async (_event, ctx) => {
		promptDepth = 0;
		await setState("done", ctx);
	});

	pi.on("session_shutdown", async () => {
		promptDepth = 0;
		await setState("off");
	});
}
