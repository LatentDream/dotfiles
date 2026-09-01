#!/usr/bin/env bash

set -euo pipefail

cleanup() {
    tmux set-environment -gu TMUX_AGENT_ANIMATION_FRAME 2>/dev/null || true
    tmux set-environment -gu TMUX_AGENT_ANIMATION_PID 2>/dev/null || true
}
trap cleanup EXIT

get_option() {
    local value
    value="$(tmux show-option -gqv '@agent-indicator-animation-speed' 2>/dev/null || true)"
    printf '%s\n' "${value:-300}"
}

tmux set-environment -g TMUX_AGENT_ANIMATION_PID "$$"
speed_ms="$(get_option)"
sleep_arg="$(printf '0.%03d' "$speed_ms" 2>/dev/null || printf '0.300')"
if [ "$speed_ms" -ge 1000 ] 2>/dev/null; then
    sleep_arg="$((speed_ms / 1000)).$(printf '%03d' "$((speed_ms % 1000))")"
fi

frame=0
while tmux list-sessions >/dev/null 2>&1 \
    && tmux show-environment -g 2>/dev/null | grep -q '_STATE=running$'; do
    tmux set-environment -g TMUX_AGENT_ANIMATION_FRAME "$frame"
    tmux refresh-client -S >/dev/null 2>&1 || true
    frame=$(( (frame + 1) % 10 ))
    sleep "$sleep_arg"
done
