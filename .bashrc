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

alias ..='cd ..'
alias 2..='cd ../..'
alias 3..='cd ../../..'
alias 4..='cd ../../../..'
alias 5..='cd ../../../../..'

alias ..l='cd .. && ls'
alias :q='exit'
alias cd..='cd ..'
alias sudp='sudo'
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
export EDITOR="/usr/bin/nvim"

# User tools directory ----------
export PATH="$HOME/tools/:$PATH"

