#!/usr/bin/env bash

context="$(kubectl config current-context 2>/dev/null)"
[ -n "$context" ] || exit 0

printf ' %s#[fg=colour7] | ' "$context"
