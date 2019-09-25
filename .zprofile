if ! pgrep -x -u "${USER}" ssh-agent > /dev/null 2>&1; then
  SSH_KEY_LIFE_TIME_SEC=3600
  eval "$(ssh-agent -t ${SSH_KEY_LIFE_TIME_SEC})" > /dev/null 2>&1
fi

[[ -f ~/.zprofile.local ]] && source ~/.zprofile.local
