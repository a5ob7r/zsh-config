# zshrc

# TIMEATSTART=$(date +%s%3N)

if [[ "${ZSH_DEBUG}" -eq 1 ]]; then
  zmodload zsh/zprof && zprof
fi

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

__exists_command() {
  whence ${1} > /dev/null
}

alias has='__exists_command'

__is_gnu_coreutils() {
  ${1} --version 2>&1 | grep -q GNU
}

alias gnu='__is_gnu_coreutils'

__is_gnu_coreutils_installed() {
  has dircolors
}

alias gnui='__is_gnu_coreutils_installed'

__list_path() {
  tr ' ' '\n' <<< "${path}"
}

alias path=__list_path

zshtimes() {
  local -ir NB_TIMES=${1}

  repeat "${NB_TIMES}"; do
    sleep 1
    time (zsh -ic exit 2> /dev/null)
  done
}

zshtimes-stat() {
  local -ir NB_TIMES=${1}

  zshtimes "${NB_TIMES}" 2>&1 \
    | tee >(cut -d ' ' -f 9 | awk '{s += $1; c += 1} END {printf "\n  AVG: %f second\n", s/c}')
}

zshcompiles() {
  local -ra ZSH_CONFIGS=( \
    ~/.zshenv \
    ~/.zprofile \
    ~/.zshrc \
    ~/.zlogin \
  )

  zsh_compile() {
    local -ra CONFIGS=( \
      "${1}" \
      "${1}.local" \
    )

    for c in "${CONFIGS[@]}"; do
      if [[ -f "${c}" ]]; then
        zcompile "${c}"
        echo "Compiled: ${c}"
      fi
    done
  }

  for zc in "${ZSH_CONFIGS[@]}"; do zsh_compile "${zc}"; done
}

__fzf_use_tmux__() {
  [ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ] && [ ${LINES:-40} -gt 15 ]
}

__fzfcmd() {
  __fzf_use_tmux__ &&
    echo "fzf-tmux -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
}

__fsel() {
  local cmd="find . -mindepth 1 -maxdepth 1 -print | cut -b 3-"
  local FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS"
  setopt localoptions pipefail 2> /dev/null

  eval "$cmd" |
    $(__fzfcmd) --multi |
    while read -r item; do echo -n "${(q)item} "; done

  local ret=$?
  echo

  return $ret
}

fzf-file-widget() {
  LBUFFER="${LBUFFER}$(__fsel)"
  local ret=$?
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}

fzf-history-widget() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail 2> /dev/null
  selected=( $(fc -rl 1 |
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
  local ret=$?
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}

__cd_to_git_repository() {
  local -r REPO="$(ghq list | $(__fzfcmd))"
  [[ -n "${REPO}" ]] || return 1

  local -r GHQ_ROOT="$(ghq root)"
  cd "${GHQ_ROOT}/${REPO}" || return 1
}

fdkrmi() {
  local -ra IMAGES=( $(docker images | "$(__fzfcmd)" --multi --header-lines=1 | awk '{print $3}') )

  [[ -n "${IMAGES[*]}" ]] || return 1

  for image in "${IMAGES[@]}"; do
    docker rmi "${image}"
  done
}

fdkrm() {
  local -ra CONTAINERS=( $(docker container ls -a | "$(__fzfcmd)" --multi --header-lines=1 | awk '{print $1}') )

  [[ -n "${CONTAINERS[*]}" ]] || return 1

  for container in "${CONTAINERS[@]}"; do
    docker rm "${container}"
  done
}

__anyenv_init() {
  local -r ANYENV_ROOT=~/.anyenv
  local -r ANYENV_CONFIG_ROOT=~/.config/anyenv
  local -r ANYENV_INIT_PATH="${ANYENV_CONFIG_ROOT}/ANYENV_INIT.env"
  local -r ANYENV_INIT_EXPORT_PATH="${ANYENV_CONFIG_ROOT}/ANYENV_INIT_EXPORT.env"
  local -r ANYENV_INIT_OTHER_PATH="${ANYENV_CONFIG_ROOT}/ANYENV_INIT_OTHER.env"

  if [[ ! -d "${ANYENV_ROOT}" ]]; then
    return
  fi

  if ! has anyenv; then
    add2path "${ANYENV_ROOT}/bin"
    export path
  fi

  if [[ ! -f "${ANYENV_INIT_PATH}" ]]; then
    anyenv init - --no-rehash  > "${ANYENV_INIT_PATH}"
  fi

  if [[ ! -f "${ANYENV_INIT_EXPORT_PATH}" ]]; then
    grep -i export < "${ANYENV_INIT_PATH}" > "${ANYENV_INIT_EXPORT_PATH}"
  fi

  if [[ ! -f "${ANYENV_INIT_OTHER_PATH}" ]]; then
    grep -iv export < "${ANYENV_INIT_PATH}" > "${ANYENV_INIT_OTHER_PATH}"
  fi

  if [[ "${-}" == *l* ]]; then
    source "${ANYENV_INIT_EXPORT_PATH}"
    export path
  fi

  source "${ANYENV_INIT_OTHER_PATH}"
}


# {{{ Process for login shell
if [[ "${-}" == *l* ]]; then
  # {{{ basic
  export LANG=en_US.UTF-8
  export LC_TIME="C"

  export EDITOR=vim
  export VISUAL=vim
  export PAGER=less

  # prevent adding duplication path
  typeset -U path PATH

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
  export FZF_DEFAULT_OPTS='--reverse --height=40%'
  if has rg; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
  fi
  # }}}

  # {{{ other
  export GOPATH=~/go
  add2path "${GOPATH}/bin"
  export path

  export PIPENV_VENV_IN_PROJECT=1
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
fi
# }}}

__anyenv_init

if gnui; then
  alias grep='grep --color=auto'
  alias gr="grep -F -irn --exclude-dir='.git'"
fi

# define alias of colorful and detail ls
if has exa; then
  alias l='exa -la'
  alias lg='l -g'
  alias ll='exa -1'
elif gnui ls; then
  # when GNU LS(= coreutils) is installed
  alias ls='ls --color=auto'
  alias ll='ls -1'
  alias la='ls -lAh'
else
  # BSD LS
  alias ls='ls -GF'
  alias l='ls -ohA'
  alias ll='ls -1'
  alias la="ls -lhTA"
fi

if has docker; then
  alias dk='docker'
fi

if has docker-compose; then
  alias dkcp='docker-compose'
fi

if has tmux; then
  alias t='tmux'
fi

if has hub; then
  alias g='hub'
elif has git; then
  alias g='git'
fi

if has volt; then
  alias v='volt'
  alias vb='volt build'
fi

if has pipenv; then
  alias p='pipenv'
fi

alias cdg='__cd_to_git_repository'
alias cdh='cd ~'
alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'
alias shinit='exec $SHELL -l'

# Auto-completion
source ~/.fzf/shell/completion.zsh 2> /dev/null

# execute whenever the current working directory is changed
chpwd() {
  ll
}

setopt correct
setopt emacs
setopt extended_glob
setopt extended_history
setopt hist_expand
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify
setopt ignore_eof
setopt list_packed
setopt magic_equal_subst
setopt mark_dirs
setopt print_eight_bit
setopt prompt_subst
setopt pushd_ignore_dups
setopt share_history

unsetopt beep
unsetopt flow_control

zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' '+m:{A-Z}={a-z}'
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _match _approximate _list
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-separator '->'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache true
zstyle ':completion:*:messages' format '%F{yellow}%d%f'
zstyle ':completion:*:warnings' format '%F{red}No matches for:%f %F{yellow}%d%f'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:default' menu select=2

zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

zle     -N   fzf-history-widget
bindkey '^R' fzf-history-widget
zle     -N   fzf-file-widget
bindkey '^T' fzf-file-widget

! [[ -d ~/.zinit ]] \
  && sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"

source ~/.zinit/bin/zinit.zsh

# If you place the source below compinit,
# then add those two lines after the source:
#autoload -Uz _zinit
#(( ${+_comps} )) && _comps[zinit]=_zinit

zinit ice wait blockf lucid
zinit light 'zsh-users/zsh-completions'

zinit ice wait atload"_zsh_autosuggest_start" lucid
zinit light 'zsh-users/zsh-autosuggestions'

zinit ice wait atinit"zpcompinit; zpcdreplay" lucid
zinit light 'zdharma/fast-syntax-highlighting'

PS1="> "
zinit ice wait'!' pick"async.zsh" src"pure.zsh" lucid
zinit light 'sindresorhus/pure'

zinit ice wait lucid
zinit light 'b4b4r07/enhancd'

zinit ice wait atclone"dircolors -b LS_COLORS > c.zsh" atpull'%atclone' pick"c.zsh" has"dircolors" lucid
zinit light trapd00r/LS_COLORS

# Prevents .zshrc updating by zinit installer.
# <<zinit>>

if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi

if has zprof; then
  zprof | less
fi

# TIMEATEND=$(date +%s%3N)
# STARTUPTIME=$(bc <<< "${TIMEATEND} - ${TIMEATSTART}")
# echo "startup time: ${STARTUPTIME} ms" >&2
# unset TIMEATSTART TIMEATEND STARTUPTIME
