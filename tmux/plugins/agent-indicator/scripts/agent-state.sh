#!/usr/bin/env bash

set -euo pipefail

usage() {
    printf 'Usage: agent-state.sh --agent <name> --state <running|needs-input|done|off> [--pane <pane-id>]\n' >&2
}

get_env() {
    tmux show-environment -g "$1" 2>/dev/null | sed 's/^[^=]*=//' || true
}

get_option() {
    local option="$1" default_value="$2" value
    value="$(tmux show-option -gqv "$option" 2>/dev/null || true)"
    printf '%s\n' "${value:-$default_value}"
}

pane_exists() {
    [ -n "${1:-}" ] && tmux display-message -p -t "$1" '#{pane_id}' >/dev/null 2>&1
}

resolve_pane() {
    local agent="$1" requested="$2" candidate state fallback=""
    if pane_exists "$requested"; then
        printf '%s\n' "$requested"
        return
    fi
    if pane_exists "${TMUX_PANE:-}"; then
        printf '%s\n' "$TMUX_PANE"
        return
    fi
    while IFS= read -r candidate; do
        candidate="${candidate#TMUX_AGENT_PANE_}"
        candidate="${candidate%%_AGENT=*}"
        pane_exists "$candidate" || continue
        state="$(get_env "TMUX_AGENT_PANE_${candidate}_STATE")"
        case "$state" in
            running|needs-input) printf '%s\n' "$candidate"; return ;;
            done) fallback="$candidate" ;;
        esac
    done < <(tmux show-environment -g 2>/dev/null | grep -F "_AGENT=${agent}" || true)
    if [ -n "$fallback" ]; then
        printf '%s\n' "$fallback"
    else
        tmux display-message -p '#{pane_id}'
    fi
}

stop_animation() {
    local pid
    pid="$(get_env 'TMUX_AGENT_ANIMATION_PID')"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
    fi
    tmux set-environment -gu TMUX_AGENT_ANIMATION_PID 2>/dev/null || true
    tmux set-environment -gu TMUX_AGENT_ANIMATION_FRAME 2>/dev/null || true
}

sync_animation() {
    if tmux show-environment -g 2>/dev/null | grep -q '_STATE=running$'; then
        case "$(get_option '@agent-indicator-animation-enabled' 'on')" in
            on|true|yes|1)
                local pid
                pid="$(get_env 'TMUX_AGENT_ANIMATION_PID')"
                if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
                    nohup bash "$(dirname "${BASH_SOURCE[0]}")/animation.sh" >/dev/null 2>&1 &
                fi
                ;;
        esac
    else
        stop_animation
    fi
}

[ -n "${TMUX:-}" ] || exit 0

agent=""
state=""
requested_pane=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --agent) agent="${2:-}"; shift 2 ;;
        --state) state="${2:-}"; shift 2 ;;
        --pane) requested_pane="${2:-}"; shift 2 ;;
        *) usage; exit 1 ;;
    esac
done

[ -n "$agent" ] && [ -n "$state" ] || { usage; exit 1; }
case "$state" in
    running|needs-input|done|off) ;;
    *) usage; exit 1 ;;
esac

pane_id="$(resolve_pane "$agent" "$requested_pane")"
state_key="TMUX_AGENT_PANE_${pane_id}_STATE"
agent_key="TMUX_AGENT_PANE_${pane_id}_AGENT"

if [ "$state" = "off" ]; then
    tmux set-environment -gu "$state_key" 2>/dev/null || true
    tmux set-environment -gu "$agent_key" 2>/dev/null || true
else
    tmux set-environment -g "$state_key" "$state"
    tmux set-environment -g "$agent_key" "$agent"
fi

sync_animation
tmux refresh-client -S >/dev/null 2>&1 || true
