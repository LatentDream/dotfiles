#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INDICATOR_COMMAND="#($CURRENT_DIR/scripts/indicator.sh #{q:pane_current_path})"

for option in status-left status-right; do
    value="$(tmux show-option -gqv "$option")"
    [ -n "$value" ] || continue
    value="${value//\#\{git_indicator\}/$INDICATOR_COMMAND}"
    tmux set-option -gq "$option" "$value"
done
