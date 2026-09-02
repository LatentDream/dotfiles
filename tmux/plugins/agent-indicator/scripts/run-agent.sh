#!/usr/bin/env bash

set -uo pipefail

if [ "$#" -lt 2 ]; then
    printf 'Usage: run-agent.sh <agent> <command> [args...]\n' >&2
    exit 2
fi

agent="$1"
shift
state_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-state.sh"

"$state_script" --agent "$agent" --state running
"$@"
status=$?
"$state_script" --agent "$agent" --state off
exit "$status"
