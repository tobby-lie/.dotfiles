# Exports
export EDITOR=nvim

# Aliases
alias vim="nvim"
alias gis="git status"
alias gp="git pull"

function gcb() {
  git checkout -b $1
}

function gpushup() {
  branch=${1:-$(git rev-parse --abbrev-ref HEAD)}
  git push --set-upstream origin "$branch"
}

alias lock="i3lock -i ~/.config/wallpaper/wallpaper.png -c 000000"

