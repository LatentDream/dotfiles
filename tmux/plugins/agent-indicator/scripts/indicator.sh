#!/usr/bin/env bash

set -euo pipefail

get_option() {
    local option="$1" default_value="$2" value
    value="$(tmux show-option -gqv "$option" 2>/dev/null || true)"
    printf '%s\n' "${value:-$default_value}"
}

get_env() {
    tmux show-environment -g "$1" 2>/dev/null | sed 's/^[^=]*=//' || true
}

is_enabled() {
    case "$1" in
        on|true|yes|1) return 0 ;;
        *) return 1 ;;
    esac
}

priority() {
    case "$1" in
        needs-input) printf '1' ;;
        done) printf '2' ;;
        running) printf '3' ;;
    esac
}

spinner_frame() {
    local frame="$1" frames="$2" values
    IFS=',' read -r -a values <<< "$frames"
    printf '%s' "${values[$((frame % ${#values[@]}))]}"
}

is_enabled "$(get_option '@agent-indicator-indicator-enabled' 'on')" || exit 0

max_entries="$(get_option '@agent-indicator-max-entries' '8')"
separator="$(get_option '@agent-indicator-separator' ' ')"
empty_text="$(get_option '@agent-indicator-empty-text' ' None')"
indicator_icon="$(get_option '@agent-indicator-icon' '')"
indicator_icon_color="$(get_option '@agent-indicator-icon-color' 'colour15')"
running_icon="$(get_option '@agent-indicator-running-icon' '󱙺')"
running_spinner="$(get_option '@agent-indicator-running-spinner' '⠋,⠙,⠹,⠸,⠼,⠴,⠦,⠧,⠇,⠏')"
input_icon="$(get_option '@agent-indicator-needs-input-icon' '󱚟')"
done_icon="$(get_option '@agent-indicator-done-icon' '󰚩')"
running_color="$(get_option '@agent-indicator-running-indicator-color' 'colour244')"
input_color="$(get_option '@agent-indicator-needs-input-indicator-color' 'yellow')"
done_color="$(get_option '@agent-indicator-done-indicator-color' 'green')"
animation_enabled="$(get_option '@agent-indicator-animation-enabled' 'on')"

records=()
while IFS= read -r line; do
    case "$line" in
        TMUX_AGENT_PANE_*_STATE=*) ;;
        *) continue ;;
    esac
    pane_id="${line#TMUX_AGENT_PANE_}"
    pane_id="${pane_id%%_STATE=*}"
    state="${line#*=}"
    case "$state" in
        running|needs-input|done) ;;
        *) continue ;;
    esac
    if ! metadata="$(tmux display-message -p -t "$pane_id" $'#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_id}' 2>/dev/null)" \
        || [ "${metadata##*$'\t'}" != "$pane_id" ]; then
        for suffix in STATE AGENT SESSION_ID SESSION_NAME; do
            tmux set-environment -gu "TMUX_AGENT_PANE_${pane_id}_${suffix}" 2>/dev/null || true
        done
        continue
    fi
    metadata="${metadata%$'\t'*}"
    records+=("$(priority "$state")"$'\t'"$metadata"$'\t'"$pane_id"$'\t'"$state")
done < <(tmux show-environment -g 2>/dev/null || true)

if [ "${#records[@]}" -eq 0 ]; then
    printf '#[fg=%s]%s#[default]%s\n' "$indicator_icon_color" "$indicator_icon" "$empty_text"
    exit 0
fi

animation_frame="$(get_env 'TMUX_AGENT_ANIMATION_FRAME')"
output="#[fg=${indicator_icon_color}]${indicator_icon}#[default] "
count=0
while IFS=$'\t' read -r _ _ _ _ pane_id state; do
    [ "$count" -lt "$max_entries" ] 2>/dev/null || break
    case "$state" in
        running) icon="$running_icon"; color="$running_color" ;;
        needs-input) icon="$input_icon"; color="$input_color" ;;
        done) icon="$done_icon"; color="$done_color" ;;
    esac
    if [ "$state" = "running" ] && is_enabled "$animation_enabled" && [ -n "$animation_frame" ]; then
        icon="$(spinner_frame "$animation_frame" "$running_spinner")"
    fi
    [ "$count" -eq 0 ] || output="${output}${separator}"
    output="${output}#[fg=${color}]${icon}#[default]"
    count=$((count + 1))
done < <(printf '%s\n' "${records[@]}" | LC_ALL=C sort -t $'\t' -k1,1n -k2,2 -k3,3n -k4,4n)

printf '%s\n' "$output"
