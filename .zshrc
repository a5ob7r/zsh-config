# zshrc

# Profiling of zsh startup process using zprof
# Define an environment variable ZSH_DEBUG and assin 1 to it if want to
# profile.
#
# How to usage
# $ export ZSH_DEBUG=1
# $ zsh
# # or
# $ ZSH_DEBUG=1 zsh
if [[ "${ZSH_DEBUG}" -eq 1 ]]; then
  zmodload zsh/zprof && zprof
fi

#######################################
# Add command path to a environment variable "path" and prevent from reorder
# them
# Global:
#   path: Command "path"
# Arguments:
#   DIRPATH: A command directory path
# Return:
#   None
#######################################
__add_directory_path_to_path_with_duplicate_check() {
  local -r DIRPATH="${1}"

  # Trim any backslashes from the tail.
  setopt local_options no_mark_dirs 2> /dev/null
  local -r PATHDIR=$(sed -E 's/\/*$//' <<< ${DIRPATH})

  if [[ -z "${path[(r)${PATHDIR}]}" ]]; then
    path=( \
      # Validate a directory path
      "${PATHDIR}"(N-/) \
      "${path[@]}" \
    )
  fi
}

alias add2path='__add_directory_path_to_path_with_duplicate_check'

#######################################
# Search whether or not a command can call from a shell prompt
# Global:
#   None
# Arguments:
#   1: A command name
# Return:
#   0 or 1: Whether or not a command can call
#######################################
__exists_command() {
  whence ${1} > /dev/null
}

alias has='__exists_command'

#######################################
# Search that whether or not a command is made by GNU
# Global:
#   None
# Arguments:
#   1: A command name
# Return:
#   0 or 1: Whether or not a command is made by GNU
#######################################
__is_gnu_coreutils() {
  ${1} --version 2>&1 | grep -q GNU
}

alias gnu='__is_gnu_coreutils'

#######################################
# Search that whether or not GNU coreutils is installed
# Global:
#   None
# Arguments:
#   None
# Return:
#   0 or 1: Whether or not GNU coreutils is installed
#######################################
__is_gnu_coreutils_installed() {
  has dircolors
}

alias gnui='__is_gnu_coreutils_installed'

#######################################
# List up path directories per line
# Global:
#   path: Command "path"
# Arguments:
#   None
# Return:
#   Path directories
#######################################
__list_path() {
  tr ' ' '\n' <<< "${path}"
}

alias path='__list_path'

#######################################
# Measure zsh start up time
# Global:
#   None
# Arguments:
#   NB_TIMES: Number of times to measure
# Return:
#   Measured times of zsh start up
#######################################
zshtimes() {
  local -ir NB_TIMES=${1}

  repeat "${NB_TIMES}"; do
    sleep 1
    time (zsh -ic exit 2> /dev/null)
  done
}

#######################################
# Measure zsh start up time and calculate mean time
# Global:
#   None
# Arguments:
#   NB_TIMES: Number of times to measure
# Return:
#   Measured times of zsh start up and mean time
#######################################
zshtimes-stat() {
  local -ir NB_TIMES=${1}

  zshtimes "${NB_TIMES}" 2>&1 \
    | tee >(cut -d ' ' -f 9 | awk '{s += $1; c += 1} END {printf "\n  AVG: %f second\n", s/c}')
}

#######################################
# Zcompile zsh user configures
# Global:
#   None
# Arguments:
#   None
# Return:
#   Compiled zsh user configure names
#######################################
zshcompiles() {
  local -ra ZSH_CONFIGS=( \
    ~/.zshenv \
    ~/.zprofile \
    ~/.zshrc \
    ~/.zlogin \
  )

  #######################################
  # Zcompile zsh user configure and local it
  # Global:
  #   None
  # Arguments:
  #   1: Zsh configure path
  # Return:
  #   Compiled zsh user configure names
  #######################################
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
  [ -n "${TMUX_PANE}" ] && [ "${FZF_TMUX:-0}" != 0 ] && [ ${LINES:-40} -gt 15 ]
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

__run-help-tmux-pane() {
  local -r CMD="${(qqq)LBUFFER}"

  if [[ -n "${TMUX_PANE}" ]]; then
    tmux split-window "man ${CMD}"
  else
    man "${CMD}"
  fi
}

# Current date and time.
alias datetime="date +'%Y%m%d%H%M%S'"

# Date only version of datetime.
alias date2="datetime | cut -c -8"

#######################################
# Make a directory which it's name is current date and time.
# Global:
#   None
# Arguments:
#   None
# Return:
#   None
#######################################
__mkdir_with_current_time() {
  mkdir "$(datetime)"
}
alias mkdir-datetime='__mkdir_with_current_time'

#######################################
# Is inside git repository.
# Global:
#   None
# Arguments:
#   None
# Return:
#   True or False
#######################################
__is_inside_git_repository() {
  [[ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" == true ]]
}

#######################################
# Show git status if in git repository.
# Global:
#   None
# Arguments:
#   PREFIX: Prefix messages
# Return:
#   None
#######################################
__git_status() {
  __is_inside_git_repository || return

  [[ "${#@}" -gt 0 ]] && echo "${1}"
  git status -sb 2> /dev/null
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

  add2path ~/.node_modules/bin
  add2path ~/.local/bin
  add2path ~/.cargo/bin
  add2path ~/.cabal/bin
  add2path ~/.ghcup/bin
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
  if has fzf; then
    export FZF_DEFAULT_OPTS='--reverse --height=40%'

    if has rg; then
      export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
    fi
  fi
  # }}}

  # {{{ other
  if has go; then
    export GOPATH=~/go
    add2path "${GOPATH}/bin"
  fi

  if has volt; then
    export VOLTPATH=~/.vim/volt
  fi

  if has pipenv; then
    export PIPENV_VENV_IN_PROJECT=1
  fi
  # }}}

  #######################################
  # Enable ssh-agent wisely. Cache ssh-agent output and load it as necessary.
  # This is to prevent duplicate ssh-agent start.
  # Global:
  #   None
  # Arguments:
  #   None
  # Return:
  #   None
  #######################################
  __enable_ssh_agent() {
    export -i SSH_KEY_LIFE_TIME_SEC=3600
    export SSH_AGENT_ENV=~/.ssh/ssh-agent.env

    # When no existing ssh-agent process
    if ! pgrep -x -u "${USER}" ssh-agent > /dev/null 2>&1; then
      # Start ssh-agent process and cache the output
      ssh-agent -t ${SSH_KEY_LIFE_TIME_SEC} > "${SSH_AGENT_ENV}"
    fi

    # When not loading ssh-agent process information
    if [[ -f "${SSH_AGENT_ENV}" && ! -v SSH_AUTH_SOCK && ! -v SSH_AGENT_PID ]]; then
      source "${SSH_AGENT_ENV}" > /dev/null 2>&1
    fi
  }

  case ${OSTYPE} in
    linux* )
      export TERMINAL='alacritty'
      export BROWSER='firefox'

      # unzip-iconv
      export ZIPINFOOPT='-OCP932'
      export UNZIPOPT='-OCP932'

      __enable_ssh_agent
      ;;
    darwin* )
      ;;
  esac

  export path

  # Plugin configures
  export ZSH_AUTOSUGGEST_USE_ASYNC=''
  export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  export PURE_PROMPT_SYMBOL=λ
fi
# }}}


if gnui; then
  alias grep='grep --color=auto'
  alias gr="grep -F -irn --exclude-dir='.git'"
fi

# define alias of colorful and detail ls
if has exa; then
  alias l='exa -aF1'
  alias ll='exa -aFl'
  alias lg='ll -g'
elif gnui ls; then
  # when GNU LS(= coreutils) is installed
  alias ls='ls --color=auto'
  alias ll='ls -1'
  alias la='ls -lAh'
else
  # BSD LS
  alias ls='ls -GFh'
  alias l='ls -1A'
  alias ll='l -o'
  alias lg='l -l'
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
alias shinit='exec ${SHELL}'

# Auto-completion
source ~/.local/share/fzf/shell/completion.zsh 2> /dev/null

# execute whenever the current working directory is changed
chpwd() {
  l
  __git_status ""
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

zle -N __run-help-tmux-pane
bindkey '^[h' __run-help-tmux-pane


# {{{ zinit
declare -A ZINIT
ZINIT[COMPINIT_OPTS]=-C
ZINIT[OPTIMIZE_OUT_DISK_ACCESSES]=1

! [[ -d ~/.zinit ]] \
  && sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"

source ~/.zinit/bin/zinit.zsh

zinit wait lucid light-mode for \
  blockf \
    zsh-users/zsh-completions \
  atinit"zicompinit; zicdreplay" \
    zdharma/fast-syntax-highlighting \
  compile"{src/*.zsh,src/strategies/*.zsh}" atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
  compile"src/*.sh" \
    b4b4r07/enhancd \
  atclone"dircolors -b LS_COLORS > c.zsh" atpull'%atclone' pick"c.zsh" has"dircolors" \
    trapd00r/LS_COLORS

zinit light-mode for \
  pick"async.zsh" src"pure.zsh" \
    sindresorhus/pure
# }}}


# {{{ Per OS
case ${OSTYPE} in
  linux* )
    __open_file_on_background() {
      xdg-open "${1}" &
    }
    alias op='__open_file_on_background'
    alias open='xdg-open'
    ;;
  darwin* )
    ;;
esac
# }}}


if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi

if has zprof; then
  zprof | less
  exit
fi
