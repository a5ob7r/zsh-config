# {{{ dotfiles
# detect and define dotfiles directory path
DOTFILES=$(dirname "$(readlink ~/.zshenv)")
export DOTFILES
# }}}

source "${DOTFILES}/lib.zsh"

# {{{ local zshenv
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
# }}}
