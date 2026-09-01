#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins"
OPENCODE_PLUGIN="$OPENCODE_DIR/opencode-tmux-agent-indicator.js"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
STATE_SCRIPT="$CURRENT_DIR/scripts/agent-state.sh"

command -v jq >/dev/null 2>&1 || {
    printf 'agent-indicator setup requires jq\n' >&2
    exit 1
}

mkdir -p "$OPENCODE_DIR" "$(dirname "$CLAUDE_SETTINGS")"
ln -sfn "$CURRENT_DIR/plugins/opencode-tmux-agent-indicator.js" "$OPENCODE_PLUGIN"

if [ ! -f "$CLAUDE_SETTINGS" ]; then
    printf '{}\n' > "$CLAUDE_SETTINGS"
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

jq --arg script "$STATE_SCRIPT" '
  def command($state): {
    type: "command",
    command: ($script + " --agent claude --state " + $state)
  };
  def hook($state): [{
    matcher: "",
    hooks: [command($state)]
  }];
  .hooks = (.hooks // {})
  | .hooks.UserPromptSubmit = [
      { matcher: "", hooks: [command("off")] },
      { matcher: "", hooks: [command("running")] }
    ]
  | .hooks.PermissionRequest = hook("needs-input")
  | .hooks.Stop = [{ hooks: [command("done")] }]
' "$CLAUDE_SETTINGS" > "$tmp"
mv "$tmp" "$CLAUDE_SETTINGS"
trap - EXIT

printf 'OpenCode: %s\nClaude: %s\n' "$OPENCODE_PLUGIN" "$CLAUDE_SETTINGS"
