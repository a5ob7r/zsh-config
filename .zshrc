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

if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi

# Prevents .zshrc updating by zplugin installer.
# <<zplugin>>
