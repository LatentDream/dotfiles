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
alias ta='tmux attach'
alias td='tmux detach'
# Software
alias v='nvim'
alias y='yazi'
alias lg='lazygit'
alias ld='lazydocker'
# Gruvbox dark colors for fd and other LS_COLORS-aware tools (truecolor).
# Files: foreground; directories: blue; links: aqua; executables: green.
export LS_COLORS='rs=0:fi=38;2;235;219;178:di=01;38;2;131;165;152:ln=38;2;142;192;124:ex=01;38;2;184;187;38:'\
'or=01;38;2;251;73;52:mi=38;2;251;73;52:pi=38;2;250;189;47:so=38;2;211;134;155:bd=38;2;254;128;25:cd=38;2;254;128;25:'\
'*.tar=38;2;251;73;52:*.gz=38;2;251;73;52:*.bz2=38;2;251;73;52:*.xz=38;2;251;73;52:*.zip=38;2;251;73;52:*.7z=38;2;251;73;52:*.zst=38;2;251;73;52:'\
'*.jpg=38;2;211;134;155:*.jpeg=38;2;211;134;155:*.png=38;2;211;134;155:*.gif=38;2;211;134;155:*.webp=38;2;211;134;155:*.svg=38;2;211;134;155:'\
'*.mp3=38;2;142;192;124:*.flac=38;2;142;192;124:*.wav=38;2;142;192;124:*.mp4=38;2;211;134;155:*.mkv=38;2;211;134;155:*.pdf=38;2;250;189;47:'

# ls
# alias ls='exa -lg --group-directories-first --sort=extension'
# alias ll='exa -lag --group-directories-first --sort=extension --classify'
# alias la='exa -lgaa --group-directories-first --sort=extension'
alias ls='lsd -lX --group-dirs first --no-symlink'
alias ll='ls -alF'
alias la='ls -A'
eval "$(zoxide init bash)"
# kubectl
alias k='kubectl'
alias kd='kubectl describe'
alias kg='kubectl get'
# justfile
alias jsut=just
alias oc=opencode
# cd
alias ..='cd ..'
alias 2..='cd ../..'
alias 3..='cd ../../..'
alias 4..='cd ../../../..'
alias 5..='cd ../../../../..'

alias ..l='cd .. && ls'
alias :q='exit'
alias cd..='cd ..'
alias sudp='sudo'
alias cc='claude --allow-dangerously-skip-permissions'
alias celar='clear'
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

# Remove the annoying starship startup warnings
export STARSHIP_LOG=error
