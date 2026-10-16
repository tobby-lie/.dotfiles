# macOS dependencies, installed by install-macos.sh via `brew bundle`

brew "git"
brew "neovim"
brew "tmux"
brew "ripgrep"  # telescope grep
brew "fd"       # telescope find_files
brew "fzf"
brew "lazygit"  # tmux prefix+g popup
brew "go"       # mason builds gopls with go
brew "tree-sitter-cli"  # nvim-treesitter builds parsers with it
brew "tfenv"
brew "jq"
brew "gh"
tap "anomalyco/tap"
brew "anomalyco/tap/opencode-v2"

cask "font-jetbrains-mono-nerd-font"  # kitty font, icons included

# kitty installed outside Homebrew makes the cask install fail on the existing app
cask "kitty" unless File.exist?("/Applications/kitty.app")
