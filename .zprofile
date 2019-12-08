# {{{ basic
export LANG=en_US.UTF-8
export LC_TIME="C"

export EDITOR=vim
export VISUAL=vim
export PAGER=less

# prevent adding duplication path
typeset -U path PATH

__add_directory_path_to_path_with_duplicate_check() {
  local -r DIRPATH="${1}"

  if [[ -z "${path[(r)$DIRPATH]}" ]]; then
    path=( \
      "${DIRPATH}"(N-/) \
      "${path[@]}" \
    )
  fi
}

alias add2path='__add_directory_path_to_path_with_duplicate_check'

add2path ~/.local/bin
add2path ~/bin
# }}}

# {{{ less
# default less option
export LESS='-ij10FMRX'
# }}}

# {{{ man
# colorized man with less
export LESS_TERMCAP_mb=$'\E[01;31m'      # Begins blinking.
export LESS_TERMCAP_md=$'\E[01;31m'      # Begins bold.
export LESS_TERMCAP_me=$'\E[0m'          # Ends mode.
export LESS_TERMCAP_se=$'\E[0m'          # Ends standout-mode.
export LESS_TERMCAP_so=$'\E[00;47;30m'   # Begins standout-mode.
export LESS_TERMCAP_ue=$'\E[0m'          # Ends underline.
export LESS_TERMCAP_us=$'\E[01;32m'      # Begins underline.
# }}}

# {{{ zsh
# history
export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000

# spelling correction prompt
export SPROMPT="zsh: correct: %F{red}%R%f -> %F{green}%r%f [No/Yes/Abort/Edit]? "
# }}}

# {{{ fzf
export FZF_DEFAULT_OPTS='--reverse'
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
export FZF_TMUX=1
# }}}

# {{{ anyenv
export ANYENV_ROOT=~/.anyenv

if [[ -d ${ANYENV_ROOT} ]] ; then
  add2path "${ANYENV_ROOT}/bin"
  eval "$(anyenv init - --no-rehash)"
fi
# }}}

# {{{ other
export GOPATH=~/go
add2path "${GOPATH}/bin"
export path

export PIPENV_VENV_IN_PROJECT=1
export SPACESHIP_CHAR_SYMBOL='❯'
export SPACESHIP_CHAR_SUFFIX=' '
# }}}

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
