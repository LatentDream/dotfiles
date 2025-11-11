# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Use VSCode instead of neovim as your default editor
# export EDITOR="code"

# Set a custom prompt with the directory revealed (alternatively use https://starship.rs)
PS1="\W \[\e]0;\w\a\]$PS1"

# My Personal Aliases ----------
# Utils
alias lt='du -sh * | sort -h'
alias hg='history|grep'
alias mnt='mount | grep -E ^/dev | column -t'
alias va='source ./venv/bin/activate'
alias tcn='mv --force -t ~/.local/share/Trash '
# Git
alias gw='git worktree list'
alias st='git status'
alias startgit='cd `git rev-parse --show-toplevel` && git checkout main && git pull'
alias cg='cd `git rev-parse --show-toplevel`'
alias adog='git log --all --decorate --oneline --graph'
# Tmux
alias t='tmux'
# Software
alias v='nvim'
alias y='yazi'
alias lg='lazygit'
alias ld='lazydocker'
# ls
alias ls='lsd -lgX --group-dirs first --no-symlink'
alias ll='ls -alF'
alias la='ls -A'
eval "$(zoxide init bash)"
# kubectl
alias k='kubectl'
alias kd='kubectl describe'
alias kg='kubectl get'
# -------------------------------

# Tmux session start
alias tt='~/.config/scripts/create_tmux_session.sh'

# k9s
K9S_CONFIG_DIR=$HOME/.config/k9s/

# Yazi sub-shell ----------------
function yy() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
	    builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# Default stuff -----------------
export EDITOR="/usr/bin/vim"

# User tools directory ----------
export PATH="$HOME/tools/:$PATH"

# Only when source for Bash (allow this to be sourced from ./zshrc)
# Enable fzf and z / zi ---------
eval "$(zoxide init bash)"
eval "$(fzf --bash)"

# Ctrl + f to find a folder + start session -------
fzf_tmux_dirs() {
    # Array of directories to search
    local search_dirs=("$@")

    # If no directories provided, set some defaults
    if [[ ${#search_dirs[@]} -eq 0 ]]; then
        search_dirs=(
            "$HOME/"
            "$HOME/repo"
            "$HOME/tmp"
            "$HOME/Documents/repo"
            "$HOME/repo/tmp"
            "$HOME/repo/scripts.git/"
        )
    fi

    # Find directories and create a clean display format
    local selected_display=$(find "${search_dirs[@]}" -maxdepth 1 -type d 2>/dev/null | \
        sed "s|^$HOME/|~/|" | \
        fzf --height 60% --reverse --border \
            --preview 'ls -la $(echo {} | sed "s|^~/|$HOME/|")' \
            --preview-window 'right:50%:wrap')

    if [[ -n "$selected_display" ]]; then
        # Convert back to full path
        local selected_dir="${selected_display/#\~/$HOME}"
        local session_name=$(basename "$selected_dir" | tr . _)

        if [[ -z "$TMUX" ]]; then
            # Not in tmux - create new session with editor window
            tmux new-session -s "$session_name" -c "$selected_dir" -n Editor "nvim; $SHELL" \; \
                new-window -n Terminal \; \
                select-window -t Editor
        else
            # In tmux - create new window in current session
            tmux new-window -c "$selected_dir" -n "$(basename "$selected_dir")"
        fi
    fi
}
bind -x '"\C-g":"fzf_tmux_dirs"'  # Ctrl+g


# opencode
export PATH=/home/latent/.opencode/bin:$PATH

source ~/dotfiles/fzf-tab/fzf-bash-completion.sh
bind -x '"\t": fzf_bash_completion'
