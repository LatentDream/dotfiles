#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INDICATOR_COMMAND="#($CURRENT_DIR/scripts/indicator.sh)"

animation_pid="$(tmux show-environment -g TMUX_AGENT_ANIMATION_PID 2>/dev/null | sed 's/^[^=]*=//' || true)"
if [ -n "$animation_pid" ] && kill -0 "$animation_pid" 2>/dev/null; then
    animation_command="$(ps -p "$animation_pid" -o args= 2>/dev/null || true)"
    case "$animation_command" in
        *'/tmux-agent-indicator/scripts/animation.sh'*)
            kill "$animation_pid" 2>/dev/null || true
            tmux set-environment -gu TMUX_AGENT_ANIMATION_PID 2>/dev/null || true
            tmux set-environment -gu TMUX_AGENT_ANIMATION_FRAME 2>/dev/null || true
            ;;
    esac
fi

for option in status-left status-right; do
    value="$(tmux show-option -gqv "$option")"
    [ -n "$value" ] || continue
    value="${value//\#\{agent_indicator\}/$INDICATOR_COMMAND}"
    value="$(printf '%s' "$value" | sed -E "s|#\([^)]*/tmux-agent-indicator/scripts/indicator\.sh\)|$INDICATOR_COMMAND|g")"
    tmux set-option -gq "$option" "$value"
done

tmux set-environment -g TMUX_AGENT_INDICATOR_DIR "$CURRENT_DIR"
tmux set-hook -g after-select-window "run-shell '$CURRENT_DIR/scripts/clear-done.sh #{window_id}'"
tmux set-hook -g after-select-pane "run-shell '$CURRENT_DIR/scripts/clear-done.sh #{window_id}'"
tmux set-hook -g client-focus-in "run-shell '$CURRENT_DIR/scripts/clear-done.sh #{window_id}'"

if tmux show-environment -g 2>/dev/null | grep -q '_STATE=running$'; then
    animation_pid="$(tmux show-environment -g TMUX_AGENT_ANIMATION_PID 2>/dev/null | sed 's/^[^=]*=//' || true)"
    if [ -z "$animation_pid" ] || ! kill -0 "$animation_pid" 2>/dev/null; then
        nohup bash "$CURRENT_DIR/scripts/animation.sh" >/dev/null 2>&1 &
    fi
fi
