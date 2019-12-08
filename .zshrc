# shellcheck shell=bash
# shellcheck disable=SC1090

# {{{ dotfiles
# detect and define dotfiles directory path
DOTFILES=$(dirname "$(readlink ~/.zshrc)")
export DOTFILES
# }}}

source "${DOTFILES}/lib.zsh"

for f in "$DOTFILES"/configs/*.zsh; do
  source "$f"
done

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Prevents .zshrc updating by zplugin installer.
# <<zplugin>>
