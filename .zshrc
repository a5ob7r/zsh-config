#
# ~/.zshrc
#

# zprof {{{
# Profiling of zsh startup process using zprof. Define an environment variable
# ZPROF if want to profile.
#
# $ ZPROF= zsh
#
if (( ${+ZPROF} )); then
  zmodload zsh/zprof && zprof
fi
# }}}

# zinit module {{{
# Zinit module to compile sourced files automatically
# Need to build a module if wanna use it.
#
# $ zinit module build
#
if [[ -f ~/.zinit/bin/zmodules/Src/zdharma/zplugin.so ]]; then
  module_path+=( ~/.zinit/bin/zmodules/Src )
  zmodload zdharma/zplugin
fi
# }}}

# ZSHOPTIONS {{{
# Completion {{{
setopt LIST_PACKED
# }}}

# Expansion and Globbing {{{
setopt EXTENDED_GLOB
setopt MAGIC_EQUAL_SUBST
setopt MARK_DIRS
# }}}

# History {{{
setopt EXTENDED_HISTORY
setopt HIST_EXPAND
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_VERIFY
setopt SHARE_HISTORY
# }}}

# Input/Output {{{
setopt CORRECT
setopt IGNORE_EOF
setopt PRINT_EXIT_VALUE

unsetopt FLOW_CONTROL
# }}}

# Prompting {{{
setopt PROMPT_SUBST
# }}}

# Zle {{{
unsetopt BEEP
# }}}
# }}}

# Functions {{{
#######################################
# Functional programming's style `filter` and `map`. This reads input from
# stdin.
# Global:
#   None
# Arguments:
#   pred: Predicate.
#   yield: Yielder.
# Return:
#   Filtered and transformed list.
#######################################
filter_map() {
  local -r pred="${1}"
  local -r yield="${2}"

  pred_f() {
    eval "${pred}"
  }

  yield_f() {
    eval "${yield}"
  }

  cat - \
    | while read subj; do
        # Prevent this function to return not 0 when the last pred_f in the
        # loop returns not 0.
        if pred_f "${subj}"; then yield_f "${subj}"; fi
      done
}

#######################################
# Functional programming's style `filter` and `map`. This reads input from
# arguments.
# Global:
#   None
# Arguments:
#   pred: Predicate.
#   yield: Yielder.
#   follow args: Input list.
# Return:
#   Filtered and transformed list.
#######################################
filter_map_() {
  local -r pred="${1}"
  local -r yield="${2}"
  shift 2

  while [[ ${#} -gt 0 ]]; do
    echo "${1}"
    shift
  done | filter_map "${pred}" "${yield}"
}

#######################################
# Functional programming's style `map`. This reads input from stdin.
# Global:
#   None
# Arguments:
#   yield: Yielder.
# Return:
#   Transformed list.
#######################################
map() {
  cat - | filter_map 'true' "${1}"
}

#######################################
# Functional programming's style `map`. This reads input from arguments.
# Global:
#   None
# Arguments:
#   yield: Yielder.
# Return:
#   Transformed list.
#######################################
map_() {
  filter_map_ 'true' "${1}" ${@[2,$]}
}

#######################################
# Functional programming's style `filter`. This reads input from stdin.
# Global:
#   None
# Arguments:
#   pred: Predicate.
# Return:
#   Filtered list.
#######################################
filter() {
  cat - | filter_map "${1}" 'echo ${1}'
}

#######################################
# Functional programming's style `filter`. This reads input from arguments.
# Global:
#   None
# Arguments:
#   pred: Predicate.
#   follow args: Input list.
# Return:
#   Filtered list.
#######################################
filter_() {
  filter_map_ "${1}" 'echo ${1}' ${@[2,$]}
}

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
add2path() {
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
has() {
  (( ${+commands[${1}]} )) || whence ${1} > /dev/null
}

#######################################
# Search that whether or not a command is made by GNU
# Global:
#   None
# Arguments:
#   1: A command name
# Return:
#   0 or 1: Whether or not a command is made by GNU
#######################################
gnu() {
  ${1} --version 2>&1 | grep -q GNU
}

#######################################
# Search that whether or not GNU coreutils is installed
# Global:
#   None
# Arguments:
#   None
# Return:
#   0 or 1: Whether or not GNU coreutils is installed
#######################################
gnui() {
  has dircolors
}

#######################################
# List up path directories per line
# Global:
#   path: Command "path"
# Arguments:
#   None
# Return:
#   Path directories
#######################################
path() {
  map_ 'echo "${1}"' "${path[@]}"
}

#######################################
# List all executables on $path.
# Global:
#   path
# Arguments:
#   None
# Return:
#   List all executable paths
#######################################
executables() {
  find "${path[@]}" -type f,l -perm /111 2>/dev/null || true
}

#######################################
# Filter all executables with fuzzy finder.
# Global:
#   path
# Arguments:
#   None
# Return:
#   A executable path
#######################################
__absolute_command_path() {
  executables | $(__fzf_wrapper)
}

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

#######################################
# Make a directory which it's name is current date and time.
# Global:
#   None
# Arguments:
#   None
# Return:
#   None
#######################################
mkdir-datetime() {
  mkdir "$(datetime)"
}

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
# }}}

# Hook functions {{{
chpwd() {
  l
  __git_status ""
}
# }}}

# Widgets {{{
fzf-history-widget() {
  setopt localoptions pipefail 2> /dev/null

  local -r FZF_OPTS="${FZF_DEFAULT_OPTS} --no-multi --nth=2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort --query=${(qqq)LBUFFER}"
  local -r NUM=$(fc -rl 1 | FZF_DEFAULT_OPTS="${FZF_OPTS}" $(__fzf_wrapper) | cut -d ' ' -f 1)
  local -r EXIT_CODE="${?}"
  [[ -n "${NUM}" ]] && zle vi-fetch-history -n "${NUM}"
  zle redisplay
  return "${EXIT_CODE}"
}

#######################################
# Widget for __absolute_command_path
# Global:
#   path
# Arguments:
#   None
# Return:
#   None
#######################################
__absolute_command_path_widget() {
  setopt localoptions pipefail 2> /dev/null

  local -r FZF_OPTS="${FZF_DEFAULT_OPTS} --no-multi --tiebreak=end --bind=ctrl-r:toggle-sort --query=${(qqq)LBUFFER}"
  LBUFFER=$(FZF_DEFAULT_OPTS="${FZF_OPTS}" __absolute_command_path)
  local -r EXIT_CODE="${?}"

  zle redisplay
  return "${EXIT_CODE}"
}
# }}}

# Login shell {{{
if [[ "${-}" == *l* ]]; then
  # {{{ basic
  export EDITOR=vim
  export VISUAL=vim
  export PAGER=less

  # prevent adding duplication path
  typeset -U path PATH

  add2path ~/.node_modules/bin
  add2path ~/.local/bin
  add2path ~/.cargo/bin
  add2path ~/.ghcup/bin
  add2path ~/.cabal/bin
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
  export HISTSIZE=1100000
  export SAVEHIST=1000000

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

  export path

  [[ "${TERM}" == "linux" ]] && oceanic_next
  # }}}

  # Functions {{{
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
  # }}}

  # Per OS {{{
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
  # }}}

  # Plugin configures {{{
  export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  export PURE_PROMPT_SYMBOL=λ
  export ENHANCD_COMMAND=c
  # }}}
fi
# }}}

# Aliases {{{
if gnui; then
  alias chmod='chmod --verbose'
  alias chown='chown --verbose'
  alias cp='cp --verbose'
  alias diff='diff --color=auto'
  alias grep='grep --color=auto'
  alias ln='ln --verbose'
  alias ls='ls --color=auto'
  alias mkdir='mkdir --verbose --parents'
  alias mv='mv --verbose'
  alias rm='rm --verbose'
  alias rmdir='rmdir --verbose'

  alias __ls='ls -hvFB'
  alias la='__ls -A'
  alias l='la -1'
  alias ll='la -o'
  alias lg='la -l'
  alias gr="grep -F -irn --exclude-dir='.git'"
else
  # BSD
  alias ls='ls -G'

  alias __ls='ls -Fh'
  alias la='__ls -A'
  alias l='la -1'
  alias ll='la -o'
  alias lg='la -l'
fi

# define alias of colorful and detail ls
if has exa; then
  alias __exa="exa -F --ignore-glob='.*~'"
  alias la='__exa -a'
  alias l='la -1'
  alias ll='la -l'
  alias lg='ll -g'
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
alias fzfd='FZF_DEFAULT_COMMAND="find . -type d" fzf'

alias cg='__cd_to_git_repository'
alias cdh='cd ~'
alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'
alias shinit='exec ${SHELL}'
alias zshinit='zshcompiles > /dev/null 2>&1 && shinit'
alias q='exit'
alias :q='q'

# Current date and time.
alias datetime="date +'%Y%m%d%H%M%S'"
# Date only version of datetime.
alias date2="datetime | cut -c -8"
# }}}

# Zstyle {{{
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z-_}={A-Za-z_-}'
zstyle ':completion:*' menu select
# }}}

# Key bindings {{{
bindkey -e

zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

zle     -N   fzf-history-widget
bindkey '^R' fzf-history-widget

zle -N __absolute_command_path_widget
bindkey '^x^p' __absolute_command_path_widget
# }}}

# Plugins {{{
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
    sindresorhus/pure \
  ;
# }}}

# sindresorhus/pure {{{
zstyle :prompt:pure:git:stash show yes
# }}}
# }}}

# Per OS {{{
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

# Others {{{
source ~/.zshrc.local 2> /dev/null
# }}}

# zprof {{{
if has zprof; then
  zprof | less
  exit
fi
# }}}

# vim: set foldmethod=marker :
