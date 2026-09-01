export const TmuxAgentIndicator = async ({ $ }) => {
  const dir = process.env.TMUX_AGENT_INDICATOR_DIR
    || `${process.env.HOME}/dotfiles/tmux/plugins/agent-indicator`;
  const script = `${dir}/scripts/agent-state.sh`;

  let lastState = "off";
  let idleAt = 0;

  const setState = async (state) => {
    if (state === lastState) return;
    lastState = state;
    try {
      if (state === "running") {
        await $`bash ${script} --agent opencode --state off`;
      }
      await $`bash ${script} --agent opencode --state ${state}`;
    } catch {
      // tmux may not be available.
    }
  };

  return {
    event: async ({ event }) => {
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
