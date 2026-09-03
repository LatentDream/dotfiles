export const TmuxAgentIndicator = async ({ $, client }) => {
  const dir = process.env.TMUX_AGENT_INDICATOR_DIR
    || `${process.env.HOME}/dotfiles/tmux/plugins/agent-indicator`;
  const script = `${dir}/scripts/agent-state.sh`;

  let lastState = "off";
  let idleAt = 0;
  let activeSessionID = "";

  const setSession = async (sessionID, title = "") => {
    if (!sessionID) return;
    try {
      const response = await client.session.get({ path: { id: sessionID } });
      const session = response.data;
      if (session?.parentID) return;
      title = title || session?.title || "";
      activeSessionID = sessionID;
      await $`bash ${script} --agent opencode --session-id ${sessionID} --session-name ${title}`;
    } catch {
      // Session metadata is optional; state reporting should keep working.
    }
  };

  const setState = async (state) => {
    if (state === lastState) return;
    lastState = state;
    try {
      await $`bash ${script} --agent opencode --state ${state}`;
      if (state === "off") activeSessionID = "";
    } catch {
      // tmux may not be available.
    }
  };

  return {
    event: async ({ event }) => {
      const sessionID = event.properties?.sessionID || event.properties?.info?.id;
      const title = event.properties?.info?.title || "";
      const info = event.properties?.info;
      if (sessionID && (!info?.parentID) && (!activeSessionID || sessionID === activeSessionID || event.type === "session.status")) {
        await setSession(sessionID, title);
      }
      if (event.type === "session.status"
          && event.properties.status.type === "busy") {
        if (Date.now() - idleAt < 2000) return;
        await setState("running");
      }
      if (event.type === "permission.updated"
          || event.type === "permission.asked") {
        await setState("needs-input");
      }
      if (event.type === "session.idle" || event.type === "session.error") {
        idleAt = Date.now();
        await setState("done");
      }
    },
    "permission.ask": async () => {
      await setState("needs-input");
    },
    "tool.execute.before": async (input) => {
      if (input.tool === "question") {
        await setState("needs-input");
      }
    },
  };
};
