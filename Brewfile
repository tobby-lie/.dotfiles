# macOS dependencies, installed by install-macos.sh via `brew bundle`

brew "git"
brew "neovim"
brew "tmux"
brew "ripgrep"  # telescope grep
brew "fd"       # telescope find_files
brew "fzf"
brew "lazygit"  # tmux prefix+g popup
brew "go"       # mason builds gopls with go
brew "tfenv"
brew "jq"
brew "gh"

# kitty installed outside Homebrew makes the cask install fail on the existing app
cask "kitty" unless File.exist?("/Applications/kitty.app")
