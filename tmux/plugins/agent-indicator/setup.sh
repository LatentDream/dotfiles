#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins"
OPENCODE_PLUGIN="$OPENCODE_DIR/opencode-tmux-agent-indicator.js"
PI_DIR="$HOME/.pi/agent/extensions"
PI_EXTENSION="$PI_DIR/pi-tmux-agent-indicator.ts"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
STATE_SCRIPT="$CURRENT_DIR/scripts/agent-state.sh"
CLAUDE_STATUSLINE="$CURRENT_DIR/scripts/claude-statusline.sh"

command -v jq >/dev/null 2>&1 || {
    printf 'agent-indicator setup requires jq\n' >&2
    exit 1
}

mkdir -p "$OPENCODE_DIR" "$PI_DIR" "$(dirname "$CLAUDE_SETTINGS")"
ln -sfn "$CURRENT_DIR/plugins/opencode-tmux-agent-indicator.js" "$OPENCODE_PLUGIN"
ln -sfn "$CURRENT_DIR/plugins/pi-tmux-agent-indicator.ts" "$PI_EXTENSION"

if [ ! -f "$CLAUDE_SETTINGS" ]; then
    printf '{}\n' > "$CLAUDE_SETTINGS"
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

jq --arg script "$STATE_SCRIPT" --arg statusline "$CLAUDE_STATUSLINE" '
  def command($state): {
    type: "command",
    command: (($script | @sh) + " --agent claude --state " + $state + " --hook-json")
  };
  def hook($state): [{
    matcher: "",
    hooks: [command($state)]
  }];
  .hooks = (.hooks // {})
  | .hooks.SessionStart = hook("running")
  | .hooks.UserPromptSubmit = hook("running")
  | .hooks.PermissionRequest = hook("needs-input")
  | .hooks.Stop = [{ hooks: [command("done")] }]
  | .statusLine = { type: "command", command: ($statusline | @sh) }
' "$CLAUDE_SETTINGS" > "$tmp"
mv "$tmp" "$CLAUDE_SETTINGS"
trap - EXIT

printf 'OpenCode: %s\nPi: %s\nClaude: %s\n' "$OPENCODE_PLUGIN" "$PI_EXTENSION" "$CLAUDE_SETTINGS"
