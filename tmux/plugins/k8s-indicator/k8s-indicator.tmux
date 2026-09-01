#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for option in status-left status-right; do
    value="$(tmux show-option -gqv "$option")"
    [ -n "$value" ] || continue
    value="${value//\#\{k8s_indicator\}/#($CURRENT_DIR/scripts/indicator.sh)}"
    tmux set-option -gq "$option" "$value"
done
