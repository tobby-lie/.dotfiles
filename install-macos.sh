#!/bin/bash
#
# One-shot macOS setup.
#
# Fresh machine:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tobby-lie/.dotfiles/main/install-macos.sh)"
#
# From an existing clone:
#   ./install-macos.sh
#
# Safe to re-run. Finished steps are skipped, and any existing config that
# would be replaced gets moved to ~/.dotfiles-backup/<timestamp>/ first.

set -euo pipefail

REPO_URL="https://github.com/tobby-lie/.dotfiles.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.config/.dotfiles}"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Symlink $1 to $2, backing up whatever is already at $2
link() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        log_info "$dest is already linked"
        return
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mkdir -p "$BACKUP_DIR$(dirname "$dest")"
        mv "$dest" "$BACKUP_DIR$dest"
        log_warning "Moved existing $dest to $BACKUP_DIR$dest"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    log_info "Linked $dest -> $src"
}

check_macos() {
    if [ "$(uname)" != "Darwin" ]; then
        log_error "This script is for macOS, use install-ubuntu.sh or install-fedora.sh on Linux"
        exit 1
    fi
}

load_brew() {
    local brew_bin
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$brew_bin" ]; then
            eval "$("$brew_bin" shellenv)"
            return 0
        fi
    done
    return 1
}

install_homebrew() {
    if load_brew; then
        log_info "Homebrew is already installed"
        return
    fi

    log_info "Installing Homebrew (also installs the Xcode Command Line Tools)..."

    # The installer only uses sudo non-interactively, so ask for the password
    # once here and keep it cached until this script exits
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew
}

compiler_works() {
    local dir
    dir="$(mktemp -d)"
    printf 'int main(void) { return 0; }\n' > "$dir/test.c"
    if cc "$dir/test.c" -o "$dir/test" >/dev/null 2>&1; then
        rm -rf "$dir"
        return 0
    fi
    rm -rf "$dir"
    return 1
}

# nvim's treesitter parsers are compiled with cc. The Homebrew installer only
# installs the Command Line Tools when they're missing, so a half-applied
# update can leave cc unable to link anything with no error until nvim opens
check_toolchain() {
    log_info "Checking the C compiler works..."
    if compiler_works; then
        return
    fi

    # softwareupdate can only fix the Command Line Tools, not a full Xcode
    if [ "$(xcode-select -p 2>/dev/null)" = "/Library/Developer/CommandLineTools" ]; then
        local label
        label="$(softwareupdate --list 2>&1 | sed -n 's/^\* Label: //p' | grep '^Command Line Tools' | sort -V | tail -1 || true)"
        if [ -n "$label" ]; then
            log_warning "The C compiler can't build anything, installing $label..."
            # A failed install (offline, blocked by IT) falls through to the error below
            if sudo softwareupdate --install "$label" && compiler_works; then
                log_info "The C compiler works now"
                return
            fi
        fi
    fi

    log_error "The C compiler can't build anything, so nvim's treesitter parsers won't compile"
    log_error "Install or update the Command Line Tools (System Settings > General > Software Update, or xcode-select --install), then re-run this script"
    exit 1
}

clone_dotfiles() {
    # Run from inside a clone: use that clone as-is
    local script_dir=""
    if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi
    if [ -n "$script_dir" ] && [ -f "$script_dir/Brewfile" ]; then
        DOTFILES_DIR="$script_dir"
        log_info "Using dotfiles at $DOTFILES_DIR"
        return
    fi

    if [ -d "$DOTFILES_DIR/.git" ]; then
        log_info "Updating dotfiles in $DOTFILES_DIR..."
        git -C "$DOTFILES_DIR" pull --ff-only
    else
        log_info "Cloning dotfiles into $DOTFILES_DIR..."
        mkdir -p "$(dirname "$DOTFILES_DIR")"
        git clone "$REPO_URL" "$DOTFILES_DIR"
    fi
}

install_dependencies() {
    log_info "Installing Homebrew packages from Brewfile..."
    brew bundle --file="$DOTFILES_DIR/Brewfile"
}

link_configs() {
    log_info "Linking configuration files..."

    link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    link "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
    link "$DOTFILES_DIR/kitty" "$HOME/.config/kitty"
    link "$DOTFILES_DIR/cf" "$HOME/.config/cf"
}

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_info "oh-my-zsh is already installed"
        return
    fi

    log_info "Installing oh-my-zsh..."
    # KEEP_ZSHRC stops the installer from replacing the linked ~/.zshrc
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_fonts() {
    log_info "Installing fonts..."

    local font_dir="$HOME/Library/Fonts"
    local font
    mkdir -p "$font_dir"

    # Only .ttf/.otf, macOS can't install the web font formats in .fonts
    for font in "$DOTFILES_DIR"/.fonts/*.ttf "$DOTFILES_DIR"/.fonts/*.otf; do
        [ -f "$font" ] || continue
        if [ ! -f "$font_dir/$(basename "$font")" ]; then
            cp "$font" "$font_dir/"
        fi
    done
}

setup_tmux() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [ ! -d "$tpm_dir" ]; then
        log_info "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    fi

    log_info "Installing tmux plugins..."

    # tpm needs a running server. Use a throwaway one on its own socket so any
    # open sessions, including the one running this script, are left alone
    local socket_dir
    socket_dir="$(mktemp -d)"
    env -u TMUX TMUX_TMPDIR="$socket_dir" tmux new-session -d -s dotfiles-install
    env -u TMUX TMUX_TMPDIR="$socket_dir" "$tpm_dir/bin/install_plugins"
    env -u TMUX TMUX_TMPDIR="$socket_dir" tmux kill-server
    rm -rf "$socket_dir"
}

install_nvm() {
    local version="v0.40.7"
    local sha256="066ce4eaf4d78eaa6410433bc9ba58faaba646157cbbed6109153e6c24c5f8a5"
    export NVM_DIR="$HOME/.nvm"

    if [ -s "$NVM_DIR/nvm.sh" ]; then
        log_info "nvm is already installed"
    else
        log_info "Installing nvm $version..."
        local installer
        installer="$(mktemp)"
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$version/install.sh" -o "$installer"
        echo "$sha256  $installer" | shasum -a 256 -c -

        # The installer errors if $NVM_DIR is set but missing. PROFILE=/dev/null
        # keeps it from appending to the symlinked .zshrc, which already loads nvm
        mkdir -p "$NVM_DIR"
        PROFILE=/dev/null bash "$installer"
        rm -f "$installer"
    fi

    log_info "Installing the latest Node LTS as the nvm default..."
    # nvm.sh doesn't work under set -eu, so run it in a plain bash
    bash -c 'source "$NVM_DIR/nvm.sh" && nvm install --lts && nvm alias default "lts/*"'
}

install_nvim_plugins() {
    log_info "Installing neovim plugins at the versions pinned in lazy-lock.json..."
    nvim --headless "+Lazy! restore" +qa
}

install_safe_chain() {
    local version="1.5.20"
    local sha256="0ad25efe15d1fa56105157a454d647223e78eb0c53d1f85e3d10afcd722e7bfd"
    local installer
    local zdotdir

    # The installer's own version check misses ~/.safe-chain/bin when it isn't
    # on PATH yet, so it would re-download every run
    if "$HOME/.safe-chain/bin/safe-chain" --version 2>/dev/null | grep -q "$version"; then
        log_info "safe-chain $version is already installed"
        return
    fi

    installer="$(mktemp)"
    zdotdir="$(mktemp -d)"

    log_info "Installing Aikido safe-chain $version..."
    curl -fsSL "https://github.com/AikidoSec/safe-chain/releases/download/$version/install-safe-chain.sh" -o "$installer"
    echo "$sha256  $installer" | shasum -a 256 -c -

    # safe-chain setup appends `source /Users/<you>/.safe-chain/...` to
    # $ZDOTDIR/.zshrc, which would write into the repo through the symlink.
    # Send that to a scratch dir, .zshrc already sources it via $HOME
    ZDOTDIR="$zdotdir" sh "$installer"
    rm -rf "$installer" "$zdotdir"
}

# Main installation
main() {
    log_info "Starting macOS dotfiles installation..."

    check_macos
    install_homebrew
    check_toolchain
    clone_dotfiles
    install_dependencies
    install_nvm
    link_configs
    install_oh_my_zsh
    install_fonts
    setup_tmux
    install_nvim_plugins
    install_safe_chain

    log_info "Installation complete!"
    log_info "Open a new terminal (or run 'exec zsh') to load the shell config"
    log_info "Mason LSP servers and treesitter parsers finish installing the first time nvim opens"
    if [ -d "$BACKUP_DIR" ]; then
        log_warning "Replaced configs were backed up to $BACKUP_DIR"
    fi
}

main
