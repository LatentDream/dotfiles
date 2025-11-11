source ~/.config/.bashrc

# zi & fzf
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# Makefile completion
zstyle ':completion:*:*:make:*' tag-order 'targets'
autoload -U compinit && compinit

# Define the function
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

# Widget that inserts the command into the buffer and executes it
fzf_tmux_dirs_widget() {
    BUFFER="fzf_tmux_dirs"
    zle accept-line
}

zi_widget() {
    BUFFER="zi"
    zle accept-line
}

# Register widgets
zle -N fzf_tmux_dirs_widget
zle -N zi_widget

# Bind keys
bindkey '^g' fzf_tmux_dirs_widget  # Ctrl+g
bindkey '^f' zi_widget             # Ctrl+f

# Bind clear on Ctrl+P as Ctrl+l is for tmux-vim binding
bindkey '^P' clear-screen

# Command Prompt
# Load version control information
autoload -Uz vcs_info
precmd() { vcs_info }

# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{#b8bb26} ●%f"
zstyle ':vcs_info:git:*' unstagedstr "%F{#fb4934} ●%f"
zstyle ':vcs_info:git:*' formats " %F{#d79921}(%b)%f%c%u"
zstyle ':vcs_info:git:*' actionformats " %F{#d79921}(%b|%a)%f%c%u"

setopt PROMPT_SUBST
PROMPT='%F{#83a598}Latent%f %F{#ebdbb2}%~%f${vcs_info_msg_0_} %F{#98971a}%%%f '

alias merl='EDITOR=nvim merlion --local --compact'

export PATH="$PATH:$HOME/dotfiles/bin/"

autoload -U compinit; compinit
source ~/dotfiles/fzf-tab/fzf-tab.plugin.zsh
