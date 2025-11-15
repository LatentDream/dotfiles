# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc
source ~/dotfiles/.bashrc

# Use VSCode instead of neovim as your default editor
# export EDITOR="code"

# Set a custom prompt with the directory revealed (alternatively use https://starship.rs)
PS1="\W \[\e]0;\w\a\]$PS1"

# Enable fzf and z / zi ---------
eval "$(zoxide init bash)"
eval "$(fzf --bash)"

# opencode
export PATH=$HOME/.opencode/bin:$PATH
export PATH=$HOME/dotfiles/bin:$PATH

source ~/dotfiles/fzf-tab/fzf-bash-completion.sh
bind -x '"\t": fzf_bash_completion'

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
bind -x '"\C-f":"zi"'             # Ctrl+f
