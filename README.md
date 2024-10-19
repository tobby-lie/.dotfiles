# .dotfiles

TODO: Automate the initial install process into a .sh script

# Usage

## Neovim
Install `neovim` from source: https://github.com/neovim/neovim/blob/master/INSTALL.md#install-from-source

Clone this repo into your `~/.config` directory, when you open up `nvim`, `lazy.nvim` will automatically load the plugins. 

NOTE: `ripgrep` must be installed for this config to work.

## Bash
In addition, run the `bash_init.sh` script to symlink the `.bashrc` file into the proper path and `source` it.

## Terminal emulator
TODO: WIP -> configure kitty
[kitty](https://sw.kovidgoyal.net/kitty/)

There is a minimal `/kitty/kitty.conf` and you can run `kitty -c /kitty/kitty.conf` to activate it

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
`prefix` + `I`

## Npm
`Node.js` is required for some lsp things (`apt-get install npm`)

Note: Sometimes your node may become stale, go here to get the most up to date version -- https://nodejs.org/en/download/package-manager
    this is pertinent so that the lsp works as intended.

## gcc
`gcc` is required for some lsp things (`apt-get install gcc`)

## i3
To get started with `i3`, I just use a machine running `ubuntu-server` and run the following commands to get into `i3`
```
sudo apt install i3
```
```
sudo apt install xinit
```
```
startx
```

* Helpful `i3` series: https://www.youtube.com/playlist?list=PL5ze0DjYv5DbCv9vNEzFmP6sU7ZmkGzcf

## feh
I use `feh` (`sudo apt install feh`) to load my wall paper in my `i3` config

## fonts
The `.fonts` folder must be copied into the system's `~/.fonts` folder

## playerctl
`playerctl` is required for `i3` config (`sudo apt install playerctl`)

## xrander
Perhaps `xrander` config in `i3` could be useful?

## i3blocks
TODO: WIP -> set up i3blocks
`i3blocks` is used to customize the `i3` status block (`sudo apt install i3blocks`)

## timedatectl
To fix the timezone of a VM you can run
`$ sudo timedatectl set-timezone <timezone>`
`$ timedatectl`
