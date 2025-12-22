#!/bin/bash

# Dotfiles management with GNU Stow

# Default OS detection (can be overridden via --os)
OS_TYPE=""

# Define packages per OS
PACKAGES_LINUX=("gitconfig" "nvim" "tmux" "bash" "k9s" "lsd" "scripts" "zed" "yazi" "merlion" "scripts", "wezterm", "atuin", "starship")
PACKAGES_MAC=("gitconfig" "nvim" "tmux" "zsh" "karabiner" "lazygit" "btop" "jetbrains" "k9s" "lsd" "merlion" "scripts" "yazi" "zed", "atuin", "starship")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print helpers
print_status() { echo -e "${GREEN}✅${NC} $1"; }
print_error()  { echo -e "${RED}❌${NC} $1"; }
print_info()   { echo -e "${BLUE}ℹ️${NC}  $1"; }
print_warning(){ echo -e "${YELLOW}⚠️${NC}  $1"; }

# Usage info
usage() {
    echo "Usage: $0 [--os linux|mac] <COMMAND>"
    echo ""
    echo "Commands:"
    echo "  stow-all           Stow all dotfiles"
    echo "  unstow-all         Unstow all dotfiles"
    echo "  restow-all         Restow all dotfiles (unstow then stow)"
    echo "  stow <package>     Stow individual package"
    echo "  unstow <package>   Unstow individual package"
    echo "  dry-run            Show what would be stowed (dry run)"
    echo "  check-conflicts    Check for conflicts before stowing"
    echo "  status             Show status of stowed packages"
    echo "  cleanup            Clean up broken symlinks"
    echo "  help               Show this help message"
    echo ""
    echo "Options:"
    echo "  --os linux|mac     Force OS type (default: auto-detect)"
}

# Determine package list based on OS
get_packages() {
    if [[ "$OS_TYPE" == "linux" ]]; then
        echo "${PACKAGES_LINUX[@]}"
    elif [[ "$OS_TYPE" == "mac" ]]; then
        echo "${PACKAGES_MAC[@]}"
    else
        print_warning "Unknown OS type. Defaulting to Linux packages."
        echo "${PACKAGES_LINUX[@]}"
    fi
}

# Stow all
stow_all() {
    local packages=($(get_packages))
    print_info "Stowing all dotfiles for OS: $OS_TYPE"
    for package in "${packages[@]}"; do
        echo "Stowing $package..."
        if stow "$package" 2>/dev/null; then
            print_status "$package stowed successfully"
        else
            print_error "Failed to stow $package"
        fi
    done
    print_status "All dotfiles processed!"
}

# Unstow all
unstow_all() {
    local packages=($(get_packages))
    print_info "Unstowing all dotfiles for OS: $OS_TYPE"
    for package in "${packages[@]}"; do
        echo "Unstowing $package..."
        if stow -D "$package" 2>/dev/null; then
            print_status "$package unstowed successfully"
        else
            print_error "Failed to unstow $package"
        fi
    done
    print_status "All dotfiles processed!"
}

# Restow all
restow_all() {
    local packages=($(get_packages))
    print_info "Restowing all dotfiles for OS: $OS_TYPE"
    for package in "${packages[@]}"; do
        echo "Restowing $package..."
        if stow -R "$package" 2>/dev/null; then
            print_status "$package restowed successfully"
        else
            print_error "Failed to restow $package"
        fi
    done
    print_status "All dotfiles processed!"
}

# Individual stow/unstow
stow_package() {
    local package=$1
    local packages=($(get_packages))
    if [[ " ${packages[*]} " =~ " $package " ]]; then
        print_info "Stowing $package..."
        if stow "$package"; then
            print_status "$package stowed successfully"
        else
            print_error "Failed to stow $package"
        fi
    else
        print_error "Package '$package' not in OS package list: ${packages[*]}"
        exit 1
    fi
}

unstow_package() {
    local package=$1
    local packages=($(get_packages))
    if [[ " ${packages[*]} " =~ " $package " ]]; then
        print_info "Unstowing $package..."
        if stow -D "$package"; then
            print_status "$package unstowed successfully"
        else
            print_error "Failed to unstow $package"
        fi
    else
        print_error "Package '$package' not in OS package list: ${packages[*]}"
        exit 1
    fi
}

# Dry run
dry_run() {
    local packages=($(get_packages))
    print_info "Dry run - showing what would be stowed:"
    for package in "${packages[@]}"; do
        echo "Dry run for $package:"
        stow -n "$package"
        echo ""
    done
}

# Check conflicts
check_conflicts() {
    local packages=($(get_packages))
    print_info "Checking for conflicts..."
    for package in "${packages[@]}"; do
        if stow -n "$package" >/dev/null 2>&1; then
            print_status "$package: no conflicts"
        else
            print_error "$package: has conflicts"
        fi
    done
}

# Status
show_status() {
    print_info "=== Dotfiles Status ==="
    
    echo "Git config:"
    [[ -L "$HOME/.gitconfig" ]] && print_status "~/.gitconfig (stowed)" || print_error "~/.gitconfig (not stowed)"
    
    echo "Neovim config:"
    [[ -L "$HOME/.config/nvim" ]] && print_status "~/.config/nvim (stowed)" || print_error "~/.config/nvim (not stowed)"
    
    echo "Tmux config:"
    [[ -L "$HOME/.tmux.conf" ]] && print_status "~/.tmux.conf (stowed)" || print_error "~/.tmux.conf (not stowed)"
    
    echo "Zsh config:"
    [[ -L "$HOME/.zshrc" ]] && print_status "~/.zshrc (stowed)" || print_error "~/.zshrc (not stowed)"
}

# Cleanup
cleanup() {
    print_info "Cleaning up broken symlinks..."
    find "$HOME" -maxdepth 3 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
    print_status "Cleanup complete!"
}

# Check if stow is installed
check_stow() {
    if ! command -v stow &> /dev/null; then
        print_error "GNU Stow is not installed. Please install it first."
        print_info "macOS: brew install stow"
        print_info "Ubuntu/Debian: sudo apt install stow"
        print_info "Fedora: sudo dnf install stow"
        exit 1
    fi
}

# Main logic
main() {
    check_stow

    # Parse OS override
    if [[ "$1" == "--os" ]]; then
        if [[ "$2" != "linux" && "$2" != "mac" ]]; then
            print_error "Invalid OS type: $2"
            usage
            exit 1
        fi
        OS_TYPE="$2"
        shift 2
    else
        # Auto-detect OS
        uname_out="$(uname)"
        if [[ "$uname_out" == "Darwin" ]]; then
            OS_TYPE="mac"
        else
            OS_TYPE="linux"
        fi
    fi

    CMD="${1:-help}"

    case "$CMD" in
        "stow-all") stow_all ;;
        "unstow-all") unstow_all ;;
        "restow-all") restow_all ;;
        "stow")
            [[ -z "$2" ]] && { print_error "Specify package"; exit 1; }
            stow_package "$2"
            ;;
        "unstow")
            [[ -z "$2" ]] && { print_error "Specify package"; exit 1; }
            unstow_package "$2"
            ;;
        "dry-run") dry_run ;;
        "check-conflicts") check_conflicts ;;
        "status") show_status ;;
        "cleanup") cleanup ;;
        "help"|*) usage ;;
    esac
}

main "$@"

