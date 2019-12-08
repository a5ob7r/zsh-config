__enable_ssh_agent() {
  export -i SSH_KEY_LIFE_TIME_SEC=3600
  export SSH_AGENT_ENV=~/.ssh/ssh-agent.env

  if ! pgrep -x -u "${USER}" ssh-agent > /dev/null 2>&1; then
    ssh-agent -t ${SSH_KEY_LIFE_TIME_SEC} > "${SSH_AGENT_ENV}"
  fi

  if [[ -f "${SSH_AGENT_ENV}" && ! -v SSH_AUTH_SOCK && ! -v SSH_AGENT_PID ]]; then
    source "${SSH_AGENT_ENV}" > /dev/null 2>&1
  fi
}

case ${OSTYPE} in
  linux* )
    __enable_ssh_agent
    ;;
  darwin* )
    ;;
esac

[[ -f ~/.zprofile.local ]] && source ~/.zprofile.local
