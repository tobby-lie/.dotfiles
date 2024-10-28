#!/bin/bash

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

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed"
        return 1
    fi
    return 0
}

# Install required packages
install_dependencies() {
    log_info "Installing dependencies..."
    
    # Update package list
    sudo apt update

    # Install required packages
    PACKAGES=(
        "git"
        "ripgrep"
        "npm"
        "gcc"
        "i3"
        "i3blocks"
        "i3status"
        "xinit"
        "feh"
        "ffmpeg"
        "htop"
        "kitty"
        "playerctl"
        "fonts-powerline"
        "cmake"
        "unzip"
        "ninja-build"
        "gettext"
        "curl"
        "fzf"
        "xclip"
        "sysstat"  # for CPU usage
        "acpi"     # for battery status
        "lm-sensors" # for temperature
        "stow"     # for managing dotfiles
    )

    for package in "${PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log_info "Installing $package..."
            sudo apt install -y "$package"
        else
            log_info "$package is already installed"
        fi
    done
}

# Configure clipboard settings
configure_clipboard() {
    log_info "Configuring clipboard settings..."

    # Add xclip configuration to bashrc if not already present
    if ! grep -q "CLIPBOARD CONFIG" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# CLIPBOARD CONFIG
# Use xclip for clipboard integration
if command -v xclip > /dev/null; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
fi
EOF
    fi
}

# Install Neovim from source
install_neovim() {
    log_info "Installing Neovim from source..."
    
    if [ -d "/tmp/neovim" ]; then
        rm -rf /tmp/neovim
    fi
    
    git clone https://github.com/neovim/neovim.git /tmp/neovim
    cd /tmp/neovim || exit
    git checkout stable
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    cd - || exit
}

# Setup Tmux Plugin Manager
setup_tmux() {
    log_info "Setting up Tmux Plugin Manager..."
    
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
}

# Setup Node.js (latest LTS version)
setup_nodejs() {
    log_info "Setting up Node.js..."
    
    # Install Node.js using n version manager
    curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o /tmp/n
    sudo bash /tmp/n lts
    rm /tmp/n
}


# Copy dotfiles to .config
copy_dotfiles() {
    log_info "Copying configuration files..."

    # Create necessary directories
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.config/wallpaper"

    # Copy everything except special directories
    cd "$HOME/.dotfiles" || exit 1
    for dir in */; do
        dir=${dir%/} # Remove trailing slash
        if [ "$dir" != "fonts" ] && [ "$dir" != "scripts" ] && [ "$dir" != "docs" ] && \
           [ "$dir" != "wallpaper" ]; then
            log_info "Copying $dir to ~/.config/$dir..."
            rm -rf "$HOME/.config/$dir"
            cp -rf "$dir" "$HOME/.config/"
        fi
    done

    # Handle special cases
    
    # Copy wallpaper files
    if [ -d "wallpaper" ]; then
        log_info "Copying wallpapers..."
        rm -rf "$HOME/.config/wallpaper"/*
        cp -rf wallpaper/* "$HOME/.config/wallpaper/"
    fi

    # Copy .bashrc
    if [ -f ".bashrc" ]; then
        log_info "Copying .bashrc..."
        cp -f ".bashrc" "$HOME/.bashrc"
        # Source the new .bashrc
        log_info "Sourcing .bashrc..."
        source "$HOME/.bashrc"
    fi

    # Handle fonts
    if [ -d "fonts" ]; then
        log_info "Installing fonts..."
        mkdir -p "$HOME/.local/share/fonts"
        cp -rf "fonts/"* "$HOME/.local/share/fonts/" 2>/dev/null || log_warning "No fonts found to copy"
        fc-cache -f -v
    fi

    cd - || exit
}
# Set timezone
set_timezone() {
    log_info "Setting timezone..."
    
    # Check if fzf is available
    if ! command -v fzf &> /dev/null; then
        log_warning "fzf not found. Installing..."
        sudo apt install -y fzf
    fi

    # Use fzf to select timezone if available, otherwise use system default
    if command -v fzf &> /dev/null; then
        local timezone
        timezone=$(timedatectl list-timezones | fzf --prompt="Select your timezone: ")
        if [ -n "$timezone" ]; then
            sudo timedatectl set-timezone "$timezone"
            log_info "Timezone set to $timezone"
        else
            log_warning "No timezone selected, keeping current timezone"
        fi
    else
        log_error "Could not set timezone: fzf not available"
    fi
}

setup_kitty() {
    log_info "Activating kitty.conf..."
    
    kitty -c /kitty/kitty.conf
}

configure_keyboard() {
    log_info "Configuring keyboard mappings..."

    # Create .Xmodmap file
    cat > "$HOME/.Xmodmap" << 'EOF'
! Make Caps Lock into Escape
clear Lock
keycode 66 = Escape

! Clear existing modifiers
remove Control = Control_L
remove Mod1 = Alt_L
remove mod4 = Super_L

! Remap keys
! Left Alt becomes Left Control
keycode 64 = Control_L
! Left Super/Windows becomes Left Alt
keycode 133 = Alt_L Meta_L
! Original Left Control becomes Super/Windows
keycode 37 = Super_L

! Add modifiers back
add Control = Control_L
add Mod1 = Alt_L
add Mod4 = Super_L
EOF

    # Apply immediately
    xmodmap "$HOME/.Xmodmap"

    # Add to .xinitrc if not already present
    if ! grep -q "xmodmap.*Xmodmap" "$HOME/.xinitrc" 2>/dev/null; then
        echo "[[ -f ~/.Xmodmap ]] && xmodmap ~/.Xmodmap" >> "$HOME/.xinitrc"
    fi
}

# Main installation
main() {
    log_info "Starting dotfiles installation..."

    # Install dependencies
    install_dependencies

    # Configure clipboard
    configure_clipboard

    # Configure keyboard
    configure_keyboard

    # Install Neovim
    install_neovim

    # Setup Tmux
    setup_tmux

    # Setup Kitty
    setup_kitty

    # Setup Node.js
    setup_nodejs

    # Copy dotfiles
    copy_dotfiles

    # Set timezone
    set_timezone

    log_info "Installation complete!"
    log_info "Please restart your shell to apply changes"
    log_info "Run 'tmux source ~/.config/tmux/tmux.conf' to reload tmux configuration"
    log_info "Press prefix + I inside tmux to install plugins"
    log_info "Restart i3 with $mod+Shift+r to see i3blocks changes"
}

# Run main function
main
