#!/usr/bin/env bash

set -euo pipefail

target="${1:-}"
if [ -z "$target" ]; then
    target="$(tmux display-message -p '#{window_id}' 2>/dev/null || true)"
fi

while IFS= read -r line; do
    case "$line" in
        TMUX_AGENT_PANE_*_STATE=done) ;;
        *) continue ;;
    esac
    pane_id="${line#TMUX_AGENT_PANE_}"
    pane_id="${pane_id%%_STATE=*}"
    state_key="TMUX_AGENT_PANE_${pane_id}_STATE"
    pane_window="$(tmux display-message -p -t "$pane_id" '#{window_id}' 2>/dev/null || true)"
    if [ -n "$pane_window" ] && { [ -z "$target" ] || [ "$pane_window" != "$target" ]; }; then
        continue
    fi
    tmux set-environment -gu "$state_key" 2>/dev/null || true
    tmux set-environment -gu "TMUX_AGENT_PANE_${pane_id}_AGENT" 2>/dev/null || true
done < <(tmux show-environment -g 2>/dev/null || true)

tmux refresh-client -S >/dev/null 2>&1 || true
