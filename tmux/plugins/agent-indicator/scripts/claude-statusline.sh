#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
payload="$(cat)"

printf '%s' "$payload" | "$CURRENT_DIR/agent-state.sh" --agent claude --hook-json >/dev/null 2>&1 || true
statusline="$HOME/.tmux/plugins/tmux-agent-indicator/scripts/agent-limits.py"
if [ -x "$statusline" ]; then
    printf '%s' "$payload" | "$statusline" claude-statusline
fi
