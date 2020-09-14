# ~/.zshrc

# Zinit module to compile sourced files automatically
# Need to build a module if wanna use it.
#
# $ zinit module build
#
if [[ -f ~/.zinit/bin/zmodules/Src/zdharma/zplugin.so ]]; then
  module_path+=( ~/.zinit/bin/zmodules/Src )
  zmodload zdharma/zplugin
fi

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
# Trim all slashes from string tail.
# Global:
#   None
# Arguments:
#   STRING: A target string.
# Return:
#   A trimmed string.
#######################################
trim_tail_slashes() {
  sed -E 's/\/*$//' <<< "${1}"
}

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
  local -r PATHDIR=$(trim_tail_slashes ${DIRPATH})

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
# Search whether or not a command can call from a shell prompt.
#
# This function can search not only commands on PATH but also shell functions
# and shell aliases. Also, This function is fastest and practical way to search
# command on Zsh. [1] is so fast way to do that. But it can search only
# commands on PATH and can't do shell functions and shell aliases. And
# execution speed of [2] is slower than above a command, but it can search not
# only commands on PATH but also shell functions and shell aliases. So it is
# the best way if has a function which combines merits of both ways, the
# execution speed and the wide search range. This function is exactly that.
#
# [1] `(( ${+commands[<command_name>]} ))`
# [2] `whence <command_name>`
#
# Global:
#   None
# Arguments:
#   1: A command name
# Return:
#   0 or 1: Whether or not a command can call
#######################################
__exists_command() {
  (( ${+commands[${1}]} )) || whence ${1} > /dev/null
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

__fzf_wrapper() {
  echo 'fzf'
}

fzf-history-widget() {
  setopt localoptions pipefail 2> /dev/null

  local -r FZF_OPTS="${FZF_DEFAULT_OPTS} --no-multi --nth=2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort --query=${(qqq)LBUFFER}"
  local -r NUM=$(fc -rl 1 | FZF_DEFAULT_OPTS="${FZF_OPTS}" $(__fzf_wrapper) | cut -d ' ' -f 1)
  local -r EXIT_CODE="${?}"
  [[ -n "${NUM}" ]] && zle vi-fetch-history -n "${NUM}"
  zle redisplay
  return "${EXIT_CODE}"
}

__cd_to_git_repository() {
  local -r REPO="$(ghq list | $(__fzf_wrapper))"
  [[ -n "${REPO}" ]] || return 1

  local -r GHQ_ROOT="$(ghq root)"
  cd "${GHQ_ROOT}/${REPO}" || return 1
}

fdkrmi() {
  local -ra IMAGES=( $(docker images | "$(__fzf_wrapper)" --multi --header-lines=1 | awk '{print $3}') )

  [[ -n "${IMAGES[*]}" ]] || return 1

  for image in "${IMAGES[@]}"; do
    docker rmi "${image}"
  done
}

fdkrm() {
  local -ra CONTAINERS=( $(docker container ls -a | "$(__fzf_wrapper)" --multi --header-lines=1 | awk '{print $1}') )

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

#######################################
# Apply Oceanic-Nect color scheme for Linux Console.
# Global:
#   None
# Arguments:
#   None
# Return:
#   None
#######################################
oceanic_next() {
  # Oceanic Next
  /bin/echo -e "
  \e]P0121c21
  \e]P1e44754
  \e]P289bd82
  \e]P3f7bd51
  \e]P45486c0
  \e]P5b77eb8
  \e]P650a5a4
  \e]P7ffffff
  \e]P852606b
  \e]P9e44754
  \e]PA89bd82
  \e]PBf7bd51
  \e]PC5486c0
  \e]PDb77eb8
  \e]PE50a5a4
  \e]PFffffff
  "
  # get rid of artifacts
  clear
}

#######################################
# Run a process in the background and no output to stdout and stderr.
# Global:
#   None
# Arguments:
#   ARGS: Command name and the arguments.
# Return:
#   None
#######################################
__run_in_background() {
  # A way to run a command in the background and not to output some strings to
  # stdout and stderr is to run `cmd > /dev/null 2>&1`. But this way outputs to
  # stdout and stderr to show, that moving a process into the background and
  # completing a process, to a parent shell. So to prevent this problem use sub
  # shell and redirects the stdout and stderr to /dev/null.
  (eval "${*}" &) > /dev/null 2>&1
}

# {{{ Process for login shell
if [[ "${-}" == *l* ]]; then
  [ "${TERM}" = "linux" ] && oceanic_next

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

  #######################################
  # Default terminal name.
  # Global:
  #   None
  # Arguments:
  #   None
  # Return:
  #   Terninal name
  #######################################
  __default_terminal() {
    local -r TERMINALS=( \
      'alacritty' \
      'st' \
      'urxvt' \
      'xterm' \
    )

    for terminal in ${TERMINALS[@]}; do
      has "${terminal}" && { echo "${terminal}"; return }
    done
  }

  #######################################
  # Default browser name.
  # Global:
  #   None
  # Arguments:
  #   None
  # Return:
  #   Browser name
  #######################################
  __default_browser() {
    local -r BROWSERS=( \
      'firefoxdeveloperedition' \
      'firefox-developer-edition' \
      'firefox' \
      'google-chrome' \
      'chromium' \
    )

    for browser in ${BROWSERS[@]}; do
      has "${browser}" && { echo "${browser}"; return }
    done
  }

  __start_dropbox() {
    pgrep dropbox && return 1
    has dropbox-cli || return 1
    dropbox-cli start && dropbox-cli lansync n
  }

  case ${OSTYPE} in
    linux* )
      export TERMINAL="$(__default_terminal)"
      export BROWSER="$(__default_browser)"

      # unzip-iconv
      export ZIPINFOOPT='-OCP932'
      export UNZIPOPT='-OCP932'

      __enable_ssh_agent
      __run_in_background __start_dropbox
      ;;
    darwin* )
      ;;
  esac

  export path

  # Plugin configures
  export ZSH_AUTOSUGGEST_USE_ASYNC=''
  export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  export PURE_PROMPT_SYMBOL=λ
  export ENHANCD_COMMAND=c
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

alias dk='docker'
alias dkcp='docker-compose'
alias dkcpe='dkcp exec'
alias t='tmux'
alias g='git'
alias tiga='tig --all'
alias v='volt'
alias vb='volt build'
alias p='pipenv'

alias cg='__cd_to_git_repository'
alias cdh='cd ~'
alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'
alias shinit='exec ${SHELL}'
alias zshinit='zshcompiles > /dev/null 2>&1 && shinit'

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
setopt print_exit_value
setopt prompt_subst
setopt pushd_ignore_dups
setopt share_history

unsetopt beep
unsetopt flow_control

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z-_}={A-Za-z_-}'
zstyle ':completion:*' menu select

zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

zle     -N   fzf-history-widget
bindkey '^R' fzf-history-widget

zle -N __run-help-tmux-pane
bindkey '^[h' __run-help-tmux-pane


# {{{ zinit
declare -A ZINIT
ZINIT[COMPINIT_OPTS]=-C
ZINIT[OPTIMIZE_OUT_DISK_ACCESSES]=1

! [[ -d ~/.zinit ]] \
  && sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"

source ~/.zinit/bin/zinit.zsh

zinit light-mode for \
  wait lucid blockf \
    zsh-users/zsh-completions \
  wait lucid atinit"zicompinit; zicdreplay" \
    zdharma/fast-syntax-highlighting \
  wait lucid compile"{src/*.zsh,src/strategies/*.zsh}" atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
  wait lucid compile"src/*.sh" \
    b4b4r07/enhancd \
  wait lucid atclone"dircolors -b LS_COLORS > c.zsh" atpull'%atclone' pick"c.zsh" has"dircolors" \
    trapd00r/LS_COLORS \
  pick"async.zsh" src"pure.zsh" \
    sindresorhus/pure
# }}}


# {{{ Per OS
case ${OSTYPE} in
  linux* )
    alias open='xdg-open'
    alias op='__run_in_background open'
    alias ff='firefox'
    alias xc='xclip -selection clipboard -filter -rmlastnl && echo'
    alias lb='lsblk -o NAME,FSTYPE,FSVER,FSSIZE,FSUSED,FSAVAIL,FSUSE%,PARTTYPENAME,MOUNTPOINT'
    alias ip='ip -color=auto'
    alias x='startx'
    ;;
  darwin* )
    alias op='open'
    ;;
esac
# }}}


source ~/.zshrc.local 2> /dev/null

if has zprof; then
  zprof | less
  exit
fi
