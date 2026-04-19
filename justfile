set shell := ["bash", "-euo", "pipefail", "-c"]

# List available recipes
[private]
default:
    @just --list --unsorted --justfile {{justfile()}}

# ── Stow ──────────────────────────────────────────────────────────────────────

# OS-specific package lists
_packages_linux := "gitconfig nvim tmux bash k9s lsd scripts zed yazi merlion wezterm atuin starship"
_packages_mac   := "gitconfig nvim tmux zsh karabiner lazygit btop jetbrains k9s lsd merlion scripts yazi zed atuin starship"
_packages       := if os() == "macos" { _packages_mac } else { _packages_linux }

# Stow a package, or all packages when none is specified: `just stow [package]`
[group("stow")]
stow package="":
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v stow &>/dev/null; then
        echo "❌ GNU Stow is not installed."
        echo "ℹ️  macOS:          brew install stow"
        echo "ℹ️  Ubuntu/Debian:  sudo apt install stow"
        echo "ℹ️  Fedora:         sudo dnf install stow"
        exit 1
    fi
    _stow_one() {
        local pkg=$1
        echo "🔗 Stowing $pkg..."
        if stow "$pkg" 2>/dev/null; then
            echo "✅ $pkg stowed"
        else
            echo "❌ Failed to stow $pkg"
        fi
    }
    if [ -n "{{ package }}" ]; then
        _stow_one "{{ package }}"
    else
        echo "ℹ️  Stowing all packages for OS: {{ os() }}"
        for pkg in {{ _packages }}; do
            _stow_one "$pkg"
        done
        echo "✅ All packages processed!"
    fi

# Unstow a package, or all packages when none is specified: `just unstow [package]`
[group("stow")]
unstow package="":
    #!/usr/bin/env bash
    set -euo pipefail
    _unstow_one() {
        local pkg=$1
        echo "🔗 Unstowing $pkg..."
        if stow -D "$pkg" 2>/dev/null; then
            echo "✅ $pkg unstowed"
        else
            echo "❌ Failed to unstow $pkg"
        fi
    }
    if [ -n "{{ package }}" ]; then
        _unstow_one "{{ package }}"
    else
        echo "ℹ️  Unstowing all packages for OS: {{ os() }}"
        for pkg in {{ _packages }}; do
            _unstow_one "$pkg"
        done
        echo "✅ All packages processed!"
    fi

# Restow (unstow then stow) a package, or all: `just restow [package]`
[group("stow")]
restow package="":
    #!/usr/bin/env bash
    set -euo pipefail
    _restow_one() {
        local pkg=$1
        echo "🔁 Restowing $pkg..."
        if stow -R "$pkg" 2>/dev/null; then
            echo "✅ $pkg restowed"
        else
            echo "❌ Failed to restow $pkg"
        fi
    }
    if [ -n "{{ package }}" ]; then
        _restow_one "{{ package }}"
    else
        echo "ℹ️  Restowing all packages for OS: {{ os() }}"
        for pkg in {{ _packages }}; do
            _restow_one "$pkg"
        done
        echo "✅ All packages processed!"
    fi

# Dry-run stow (show what would be linked) for a package, or all
[group("stow")]
stow-dry package="":
    #!/usr/bin/env bash
    set -euo pipefail
    _dry_one() {
        echo "🔍 Dry-run for $1:"
        stow -n "$1"
        echo ""
    }
    if [ -n "{{ package }}" ]; then
        _dry_one "{{ package }}"
    else
        for pkg in {{ _packages }}; do
            _dry_one "$pkg"
        done
    fi

# Check for stow conflicts for a package, or all
[group("stow")]
stow-check package="":
    #!/usr/bin/env bash
    set -euo pipefail
    _check_one() {
        if stow -n "$1" >/dev/null 2>&1; then
            echo "✅ $1: no conflicts"
        else
            echo "❌ $1: has conflicts"
        fi
    }
    echo "ℹ️  Checking for conflicts..."
    if [ -n "{{ package }}" ]; then
        _check_one "{{ package }}"
    else
        for pkg in {{ _packages }}; do
            _check_one "$pkg"
        done
    fi

# Show stow status (key symlinks)
[group("stow")]
stow-status:
    #!/usr/bin/env bash
    _check_link() {
        local label=$1 path=$2
        echo -n "$label: "
        [[ -L "$path" ]] && echo "✅ $path (stowed)" || echo "❌ $path (not stowed)"
    }
    echo "ℹ️  === Dotfiles Status ==="
    _check_link "gitconfig" "$HOME/.gitconfig"
    _check_link "nvim     " "$HOME/.config/nvim"
    _check_link "tmux     " "$HOME/.tmux.conf"
    shell_rc="{{ if os() == "macos" { "$HOME/.zshrc" } else { "$HOME/.bashrc" } }}"
    shell_lbl="{{ if os() == "macos" { "zsh      " } else { "bash     " } }}"
    _check_link "$shell_lbl" "$shell_rc"

# Clean up broken symlinks under $HOME (depth 3)
[group("stow")]
stow-cleanup:
    #!/usr/bin/env bash
    echo "ℹ️  Cleaning up broken symlinks..."
    find "$HOME" -maxdepth 3 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
    echo "✅ Cleanup complete!"

# ── Install (common) ──────────────────────────────────────────────────────────

# Install Rust
[group("install")]
install-rust:
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Cargo utilities
[group("install")]
install-cargo-utils:
    cargo install ripgrep --locked
    cargo install zoxide --locked
    cargo install bat --locked
    cargo install just --locked
    cargo install yazi-fm yazi-cli --locked
    cargo install lsd --locked
    cargo install git-delta --locked
    cargo install just-lsp --locked
    cargo install atuin --locked
    cargo install --locked difftastic

# Decrypt and install encrypted SSH config
[group("install")]
install-config:
    echo "Decrypting SSH Config"
    age -d ./config/ssh-config.enc > ~/.ssh/config

# Install Tmux plugin manager (tpm)
[group("install")]
install-tmux:
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# ── Install (Linux) ───────────────────────────────────────────────────────────

# Install system packages (Ubuntu/Debian)
[linux]
[group("install")]
install-system-packages:
    sudo apt update
    sudo apt install -y unzip clangd gcc
    sudo apt install -y build-essential
    sudo apt install -y pkg-config
    sudo apt install -y libfontconfig1-dev
    sudo apt install -y libxcb1-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev
    sudo apt install -y age stow
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all

# Install Neovim on Linux (stable by default, pass "nightly" for nightly)
[linux]
[group("install")]
install-nvim version="stable":
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p ~/tools && cd ~/tools
    if [ "{{ version }}" = "nightly" ]; then
        echo "Installing Neovim nightly..."
        URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz"
    else
        echo "Installing Neovim stable (v0.12.1)..."
        URL="https://github.com/neovim/neovim/releases/download/v0.12.1/nvim-linux64.tar.gz"
    fi
    wget "$URL"
    tar xzvf nvim-linux64.tar.gz
    rm nvim-linux64.tar.gz
    if ! grep -q 'nvim-linux64/bin' ~/.bashrc; then
        echo 'export PATH="$HOME/tools/nvim-linux64/bin:$PATH"' >> ~/.bashrc
        echo "Added Neovim to PATH in ~/.bashrc"
    fi
    echo "Restart your shell or run: source ~/.bashrc"
    ~/tools/nvim-linux64/bin/nvim --version

# Update Neovim (Linux)
[linux]
[group("install")]
update-nvim version="stable":
    @just install-nvim {{ version }}

# Remove Neovim (Linux)
[linux]
[group("install")]
uninstall-nvim:
    rm -rf ~/tools/nvim-linux64
    sed -i '/nvim-linux64\/bin/d' ~/.bashrc
    echo "Neovim removed. Restart your shell or run: source ~/.bashrc"

# Install Go (Linux)
[linux]
[group("install")]
install-go:
    #!/usr/bin/env bash
    set -euo pipefail
    wget https://go.dev/dl/go1.26.2.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.26.2.linux-amd64.tar.gz
    rm go1.26.2.linux-amd64.tar.gz
    if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    fi
    echo "Go installed. Restart your shell or run: source ~/.bashrc"

# Install lazygit and lazydocker (Linux)
[linux]
[group("install")]
install-lazy:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p ~/tools/go
    export GOPATH=~/tools/go
    export PATH=$PATH:$GOPATH/bin
    go install github.com/jesseduffield/lazygit@latest
    go install github.com/jesseduffield/lazydocker@latest
    if ! grep -q 'tools/go/bin' ~/.bashrc; then
        echo 'export PATH="$HOME/tools/go/bin:$PATH"' >> ~/.bashrc
        echo "Added lazygit/lazydocker to PATH in ~/.bashrc"
    fi
    echo "Restart your shell or run: source ~/.bashrc"

# Install Node via nvm (WSL2 / Linux)
[linux]
[group("install")]
install-node:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo apt update && sudo apt upgrade -y
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
    # nvm is a shell function — it must be loaded before use.
    # Source it directly so we can call it in this script.
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm install node
    nvm ls
    node --version

# Run all installation steps (Linux / Ubuntu)
[linux]
[group("install")]
install-all: install-rust install-system-packages install-cargo-utils install-nvim install-go install-lazy install-tmux

# ── Install (macOS) ───────────────────────────────────────────────────────────

# Install Homebrew
[macos]
[group("install")]
install-homebrew:
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install system packages (macOS)
[macos]
[group("install")]
install-system-packages:
    brew install fzf unzip gcc age tmux luarocks stow

# Install Go (macOS)
[macos]
[group("install")]
install-go:
    brew install go

# Install lazygit and lazydocker (macOS)
[macos]
[group("install")]
install-lazy:
    brew install lazygit lazydocker

# Install dotnet SDK (macOS)
[macos]
[group("install")]
install-dotnet:
    brew install --cask dotnet-sdk
    dotnet tool install dotnet-ef --global -a arm64

# Install Rectangle window manager (macOS)
[macos]
[group("install")]
install-rectangle:
    brew install --cask rectangle

# Run all installation steps (macOS)
[macos]
[group("install")]
install-all: install-homebrew install-rust install-system-packages install-cargo-utils install-go install-lazy install-tmux install-rectangle
