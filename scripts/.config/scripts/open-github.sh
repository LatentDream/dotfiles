#!/usr/bin/env bash
cd "$(tmux display -p '#{pane_current_path}')"
url=$(git remote get-url origin | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/\.git$//')
xdg-open "$url" 2>/dev/null || open "$url" 2>/dev/null
