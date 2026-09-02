#!/usr/bin/env bash

path="$1"
[ -d "$path" ] || exit 0

option_enabled() {
    case "$(tmux show-option -gqv "$1")" in
        on|yes|true|1) return 0 ;;
        *) return 1 ;;
    esac
}

branch="$(git -C "$path" symbolic-ref --quiet --short HEAD 2>/dev/null)"
if [ -z "$branch" ]; then
    git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
    branch="$(git -C "$path" rev-parse --short HEAD 2>/dev/null)"
fi
[ -n "$branch" ] || exit 0

max_length="$(tmux show-option -gqv @git-indicator-max-length)"
case "$max_length" in
    ''|*[!0-9]*) max_length=25 ;;
esac

if [ "$max_length" -eq 0 ]; then
    exit 0
elif [ "${#branch}" -gt "$max_length" ]; then
    if [ "$max_length" -eq 1 ]; then
        branch='…'
    else
        branch_name="$branch"
        prefix_length=$((max_length / 2))
        suffix_length=$((max_length - prefix_length - 1))
        branch="${branch_name:0:prefix_length}…"
        if [ "$suffix_length" -gt 0 ]; then
            branch+="${branch_name: -suffix_length}"
        fi
    fi
fi

status=''
if option_enabled @git-indicator-status; then
    staged=0
    modified=0
    deleted=0
    renamed=0
    untracked=0
    conflicted=0
    stashed=0
    ahead=0
    behind=0

    while IFS= read -r line; do
        case "$line" in
            '# branch.ab '*)
                divergence="${line#\# branch.ab }"
                ahead="${divergence%% *}"
                behind="${divergence##* }"
                ahead="${ahead#+}"
                behind="${behind#-}"
                ;;
            '# stash '*)
                stashed="${line#\# stash }"
                ;;
            '1 '*|'2 '*)
                fields="${line#? }"
                xy="${fields%% *}"
                index_state="${xy%?}"
                worktree_state="${xy#?}"
                case "$index_state" in
                    U) conflicted=$((conflicted + 1)) ;;
                    R|C) renamed=$((renamed + 1)) ;;
                    D) deleted=$((deleted + 1)) ;;
                    .) ;;
                    *) staged=$((staged + 1)) ;;
                esac
                case "$worktree_state" in
                    U) conflicted=$((conflicted + 1)) ;;
                    R|C) renamed=$((renamed + 1)) ;;
                    D) deleted=$((deleted + 1)) ;;
                    M|T) modified=$((modified + 1)) ;;
                esac
                ;;
            'u '*)
                conflicted=$((conflicted + 1))
                ;;
            '? '*)
                untracked=$((untracked + 1))
                ;;
        esac
    done < <(git -C "$path" status --porcelain=v2 --branch --show-stash 2>/dev/null)

    counts=0
    option_enabled @git-indicator-status-counts && counts=1
    append_state() {
        local icon="$1"
        local count="$2"
        [ "$count" -gt 0 ] || return
        status+="$icon"
        [ "$counts" -eq 0 ] || status+="$count"
    }

    append_state '' "$conflicted"
    append_state '󰏖' "$stashed"
    append_state '' "$deleted"
    append_state '󰁕' "$renamed"
    append_state '󰷉' "$modified"
    append_state '' "$staged"
    append_state '󱪠' "$untracked"

    if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
        status+="⇕⇡${ahead}⇣${behind}"
    elif [ "$ahead" -gt 0 ]; then
        status+="⇡${ahead}"
    elif [ "$behind" -gt 0 ]; then
        status+="⇣${behind}"
    fi
fi

if [ -n "$status" ]; then
    printf ' %s#[fg=#fabd2f,bold] %s#[fg=colour7,nobold] | ' "$branch" "$status"
else
    printf ' %s#[fg=colour7] | ' "$branch"
fi
