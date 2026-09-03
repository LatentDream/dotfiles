#!/usr/bin/env bash

set -euo pipefail

cleanup_stale_record() {
    local pane_id="$1"
    tmux set-environment -gu "TMUX_AGENT_PANE_${pane_id}_STATE" 2>/dev/null || true
    tmux set-environment -gu "TMUX_AGENT_PANE_${pane_id}_AGENT" 2>/dev/null || true
}

get_option() {
    local option="$1" default_value="$2" value
    value="$(tmux show-option -gqv "$option" 2>/dev/null || true)"
    printf '%s\n' "${value:-$default_value}"
}

shorten_path() {
    local path="$1" max_length="$2" git_root relative display suffix prefix=""
    if ! [[ "$max_length" =~ ^[0-9]+$ ]] || [ "$max_length" -lt 4 ]; then
        max_length=36
    fi
    git_root="$(git -C "$path" rev-parse --show-toplevel 2>/dev/null || true)"
    if [ -n "$git_root" ]; then
        relative="${path#"$git_root"}"
        relative="${relative#/}"
        prefix='/'
        display="${git_root##*/}${relative:+/$relative}"
    else
        display="${path/#"$HOME"/~}"
    fi

    if [ "$(( ${#prefix} + ${#display} ))" -gt "$max_length" ] 2>/dev/null; then
        suffix="${display: -$((max_length - ${#prefix} - 2))}"
        printf '%s…/%s' "$prefix" "${suffix#/}"
    else
        printf '%s%s' "$prefix" "$display"
    fi
}

records=()
path_max_length="$(get_option '@agent-indicator-picker-path-max-length' '36')"
while IFS= read -r line; do
    case "$line" in
        TMUX_AGENT_PANE_*_STATE=needs-input) priority=1; state='waiting' ;;
        TMUX_AGENT_PANE_*_STATE=done) priority=2; state='done' ;;
        *) continue ;;
    esac

    pane_id="${line#TMUX_AGENT_PANE_}"
    pane_id="${pane_id%%_STATE=*}"
    if ! metadata="$(tmux display-message -p -t "$pane_id" $'#{session_name}\x1f#{window_index}\x1f#{pane_index}\x1f#{pane_current_command}\x1f#{pane_start_command}\x1f#{pane_current_path}\x1f#{pane_id}' 2>/dev/null)" \
        || [ "${metadata##*$'\x1f'}" != "$pane_id" ]; then
        cleanup_stale_record "$pane_id"
        continue
    fi

    metadata="${metadata%$'\x1f'*}"
    IFS=$'\x1f' read -r session window pane command start_command path <<< "$metadata"
    agent="$(tmux show-environment -g "TMUX_AGENT_PANE_${pane_id}_AGENT" 2>/dev/null | sed 's/^[^=]*=//' || true)"
    agent="${agent:-unknown}"
    command="${command:-${start_command:-unknown}}"

    # Keep each fzf candidate on one line even if external metadata is unusual.
    agent="${agent//$'\t'/ }"
    session="${session//$'\t'/ }"
    command="${command//$'\t'/ }"
    path="${path//$'\t'/ }"
    path="$(shorten_path "$path" "$path_max_length")"
    printf -v display '%-9s  %-10s  %-12.12s  %-36s  %s' \
        "$state" "$agent" "$command" "$path" "${session}:${window}.${pane}"
    records+=("${priority}"$'\t'"${pane_id}"$'\t'"${display}")
done < <(tmux show-environment -g 2>/dev/null || true)

[ "${1:-}" != '--has-agents' ] || [ "${#records[@]}" -gt 0 ]

if [ "${#records[@]}" -eq 0 ]; then
    exit 0
fi

command -v fzf >/dev/null 2>&1 || {
    tmux display-message 'Agent picker requires fzf'
    exit 1
}

selection="$(
    printf '%s\n' "${records[@]}" \
        | LC_ALL=C sort -t $'\t' -k1,1n -k3,3 \
        | fzf --reverse \
            --delimiter=$'\t' \
            --with-nth=3 \
            --header='STATE      AGENT       COMMAND       PATH                                  TARGET' \
            --prompt='Agent> '
)" || exit 0

[ -n "$selection" ] || exit 0
IFS=$'\t' read -r _ pane_id _ <<< "$selection"

if ! tmux display-message -p -t "$pane_id" '#{pane_id}' >/dev/null 2>&1; then
    cleanup_stale_record "$pane_id"
    tmux display-message 'Selected agent pane no longer exists'
    exit 1
fi

tmux switch-client -t "$pane_id"
tmux select-window -t "$pane_id"
tmux select-pane -t "$pane_id"
