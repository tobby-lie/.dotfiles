# .dotfiles

# Usage

## Neovim
Clone this repo into your `~/.config` directory, when you open up `nvim`, `lazy.nvim` will automatically load the plugins. 

## Bash
In addition, run the `bash_init.sh` script to symlink the `.bashrc` file into the proper path and `source` it.

## Tmux
This config uses the [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) for tmux plugins. You'll need to 
```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
then run (while inside of a `tmux` server)
```
tmux source ~/.config/tmux/tmux.conf
```
then run (while inside of a `tmux` server)
```
`prefix` + `I`

## Npm
`Node.js` is required for some lsp things
