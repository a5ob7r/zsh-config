if [[ -f ~/.profile ]]; then
  emulate sh -c "source $HOME/.profile"
fi

if [[ -f ~/.local.zprofile ]]; then
  builtin source ~/.local.zprofile
fi
