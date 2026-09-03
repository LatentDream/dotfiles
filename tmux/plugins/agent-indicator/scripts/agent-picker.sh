#!/usr/bin/env bash

set -euo pipefail

cleanup_stale_record() {
    local pane_id="$1"
    local suffix
    for suffix in STATE AGENT SESSION_ID SESSION_NAME; do
        tmux set-environment -gu "TMUX_AGENT_PANE_${pane_id}_${suffix}" 2>/dev/null || true
    done
}

get_option() {
    local option="$1" default_value="$2" value
    value="$(tmux show-option -gqv "$option" 2>/dev/null || true)"
    printf '%s\n' "${value:-$default_value}"
}

shorten_path() {
    local path="$1" max_length="$2" git_root relative display suffix prefix=""
    if ! [[ "$max_length" =~ ^[0-9]+$ ]] || [ "$max_length" -lt 4 ]; then
        max_length=25
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

mode='notifications'
case "${1:-}" in
    --all|--has-all-agents) mode='all' ;;
    --has-agents|'') ;;
    *) printf 'Usage: agent-picker.sh [--all|--has-agents|--has-all-agents]\n' >&2; exit 2 ;;
esac

records=()
path_max_length="$(get_option '@agent-indicator-picker-path-max-length' '25')"
detected_agents=""
if [ "$mode" = 'all' ]; then
    detected_agents="$(
        {
            tmux list-panes -a -F $'root\x1f#{pane_pid}\x1f#{pane_id}'
            ps -axo pid=,ppid=,comm= | awk '{ pid=$1; ppid=$2; $1=$2=""; sub(/^ +/, ""); printf "process\037%s\037%s\037%s\n", pid, ppid, $0 }'
        } | awk -F $'\x1f' '
            $1 == "root" { root[$2]=$3; next }
            $1 == "process" { parent[$2]=$3; command[$2]=$4 }
            END {
                for (pid in command) {
                    name=command[pid]
                    sub(/^.*\//, "", name)
                    if (name != "opencode" && name != "claude" && name != "harness") continue
                    ancestor=pid
                    while (ancestor != "" && !(ancestor in root)) ancestor=parent[ancestor]
                    if (ancestor in root && !(root[ancestor] in found)) {
                        print root[ancestor] "\037" name
                        found[root[ancestor]]=1
                    }
                }
            }
        '
    )"
fi

while IFS=$'\x1f' read -r pane_id _ session window pane _ _ path pane_title; do
    notification_state="$(tmux show-environment -g "TMUX_AGENT_PANE_${pane_id}_STATE" 2>/dev/null | sed 's/^[^=]*=//' || true)"
    tracked_agent="$(tmux show-environment -g "TMUX_AGENT_PANE_${pane_id}_AGENT" 2>/dev/null | sed 's/^[^=]*=//' || true)"
    session_name="$(tmux show-environment -g "TMUX_AGENT_PANE_${pane_id}_SESSION_NAME" 2>/dev/null | sed 's/^[^=]*=//' || true)"

    case "$notification_state" in
        needs-input) priority=1; state='waiting' ;;
        done) priority=2; state='done' ;;
        running) priority=3; state='running' ;;
        *) priority=4; state='active' ;;
    esac

    if [ "$mode" = 'notifications' ]; then
        case "$notification_state" in
            needs-input|done) agent="${tracked_agent:-unknown}" ;;
            *) continue ;;
        esac
    else
        agent="$(printf '%s\n' "$detected_agents" | awk -F $'\x1f' -v pane="$pane_id" '$1 == pane { print $2; exit }')"
        if [ -z "$agent" ]; then
            case "$notification_state" in
                running|needs-input|done) agent="${tracked_agent:-unknown}" ;;
                *) continue ;;
            esac
        fi
    fi

    if [ -z "$session_name" ]; then
        case "$agent:$pane_title" in
            opencode:'OC | '*) session_name="${pane_title#OC | }" ;;
            claude:'Claude Code'|claude:'') ;;
            claude:*) session_name="$pane_title" ;;
        esac
    fi
    session_name="${session_name:-unnamed}"

    # Keep each fzf candidate on one line even if external metadata is unusual.
    agent="${agent//$'\t'/ }"
    session_name="${session_name//$'\t'/ }"
    session="${session//$'\t'/ }"
    path="${path//$'\t'/ }"
    path="$(shorten_path "$path" "$path_max_length")"
    printf -v display '%-7s  %-8s  %-25s  %-18.18s  %s' \
        "$state" "$agent" "$path" "${session}:${window}.${pane}" "$session_name"
    records+=("${priority}"$'\t'"${pane_id}"$'\t'"${display}")
done < <(tmux list-panes -a -F $'#{pane_id}\x1f#{pane_pid}\x1f#{session_name}\x1f#{window_index}\x1f#{pane_index}\x1f#{pane_current_command}\x1f#{pane_start_command}\x1f#{pane_current_path}\x1f#{pane_title}')

while IFS= read -r line; do
    case "$line" in
        TMUX_AGENT_PANE_*_STATE=*) ;;
        *) continue ;;
    esac
    pane_id="${line#TMUX_AGENT_PANE_}"
    pane_id="${pane_id%%_STATE=*}"
    tmux display-message -p -t "$pane_id" '#{pane_id}' >/dev/null 2>&1 || cleanup_stale_record "$pane_id"
done < <(tmux show-environment -g 2>/dev/null || true)

case "${1:-}" in
    --has-agents|--has-all-agents) [ "${#records[@]}" -gt 0 ]; exit ;;
esac

if [ "${#records[@]}" -eq 0 ]; then
    exit 0
fi

command -v fzf >/dev/null 2>&1 || {
    tmux display-message 'Agent picker requires fzf'
    exit 1
}

printf -v header '%-7s  %-8s  %-23s  %-18s  %s' \
    'STATE' 'AGENT' 'PATH' 'TARGET' 'TITLE'

selection="$(
    printf '%s\n' "${records[@]}" \
        | LC_ALL=C sort -t $'\t' -k1,1n -k3,3 \
        | fzf --reverse \
            --delimiter=$'\t' \
            --with-nth=3 \
            --header="$header" \
            --prompt="$( [ "$mode" = 'all' ] && printf 'All agents> ' || printf 'Agent> ' )"
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
