# shellcheck shell=bash
# shellcheck disable=SC1090


for f in "$DOTFILES"/configs/*.zsh; do
  source "$f"
done

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Prevents .zshrc updating by zplugin installer.
# <<zplugin>>
