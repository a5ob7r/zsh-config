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
# Changing Directories {{{
setopt AUTO_CD
# }}}

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

# Job Control {{{
setopt LONG_LIST_JOBS
# }}}

# Prompting {{{
setopt PROMPT_SUBST
# }}}

# Zle {{{
unsetopt BEEP
# }}}
# }}}

# Functions {{{
is_linux () {
  case "$OSTYPE" in
    linux* )
      return 0
      ;;
    * )
      return 1
      ;;
  esac
}

is_macos () {
  case "$OSTYPE" in
    darwin* )
      return 0
      ;;
    * )
      return 1
      ;;
  esac
}

warning () {
  local prefix='' suffix=''

  if [[ -t 2 ]]; then
    prefix='\033[33m'
    suffix='\033[0m'
  fi

  echo "${prefix}${@}${suffix}" >&2
}

error () {
  local prefix='' suffix=''

  if [[ -t 2 ]]; then
    prefix='\033[31m'
    suffix='\033[0m'
  fi

  echo "${prefix}${@}${suffix}" >&2
}

# Functional programming's style `filter` and `map`. This reads input from
# stdin.
# Global:
#   None
# Arguments:
#   pred: Predicate.
#   yield: Yielder.
# Return:
#   Filtered and transformed list.
filter_map() {
  local -r pred="${1}"
  local -r yield="${2}"

  pred_f() {
    eval "${pred}"
  }

  yield_f() {
    eval "${yield}"
  }

  while read subj; do
    # Prevent this function to return not 0 when the last pred_f in the
    # loop returns not 0.
    if pred_f "${subj}"; then yield_f "${subj}"; fi
  done <&0
}

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
filter_map_() {
  local -r pred="${1}"
  local -r yield="${2}"
  shift 2

  while [[ ${#} -gt 0 ]]; do
    echo "${1}"
    shift
  done | filter_map "${pred}" "${yield}"
}

# Functional programming's style `map`. This reads input from stdin.
# Global:
#   None
# Arguments:
#   yield: Yielder.
# Return:
#   Transformed list.
map() {
  filter_map 'true' "${1}" <&0
}

# Functional programming's style `map`. This reads input from arguments.
# Global:
#   None
# Arguments:
#   yield: Yielder.
# Return:
#   Transformed list.
map_() {
  filter_map_ 'true' "${1}" ${@[2,$]}
}

# Functional programming's style `filter`. This reads input from stdin.
# Global:
#   None
# Arguments:
#   pred: Predicate.
# Return:
#   Filtered list.
filter() {
  filter_map "${1}" 'echo ${1}' <&0
}

# Functional programming's style `filter`. This reads input from arguments.
# Global:
#   None
# Arguments:
#   pred: Predicate.
#   follow args: Input list.
# Return:
#   Filtered list.
filter_() {
  filter_map_ "${1}" 'echo ${1}' ${@[2,$]}
}

# Add directory path to a environment variable "path", which is array form of
# `PATH`, if it passes through some validations.
add2path() {
  setopt LOCAL_OPTIONS NO_MARK_DIRS EXTENDED_GLOB

  # Strip any tail slashes.
  local -r candidate="${1%%/##}"

  # Add the path if no duplication. This can be achieved by `-U` option of
  # `typeset` but it moves the duplicated path to head of `path`.
  if [[ -z "${path[(r)${candidate}]}" ]]; then
    # Validates the directory path existance. This substitutes empty string if
    # no directory existance on the path.
    path=( \
      "$candidate"(N-/) \
      "${path[@]}" \
    )
  fi
}

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
has() {
  (( ${+commands[${1}]} )) || whence ${1} > /dev/null
}

# Search that whether or not a command is made by GNU
# Global:
#   None
# Arguments:
#   1: A command name
# Return:
#   0 or 1: Whether or not a command is made by GNU
gnu() {
  ${1} --version 2>&1 | grep -q GNU
}

# Search that whether or not GNU coreutils is installed
# Global:
#   None
# Arguments:
#   None
# Return:
#   0 or 1: Whether or not GNU coreutils is installed
gnui() {
  has dircolors
}

# List up path directories per line
# Global:
#   path: Command "path"
# Arguments:
#   None
# Return:
#   Path directories
path() {
  echo "${(F)path[@]}"
}

# List all executables on $path.
# Global:
#   path
# Arguments:
#   None
# Return:
#   List all executable paths
executables() {
  find "${path[@]}" -type f,l -perm /111 2>/dev/null || true
}

# Filter all executables with fuzzy finder.
# Global:
#   path
# Arguments:
#   None
# Return:
#   A executable path
__absolute_command_path() {
  executables | fuzzyfinder
}

# Swap stdout and stderr.
stdswap () {
  "$@" 3>&2 2>&1 1>&3 3>&-
}

# Measure zsh start up time.
zshtimes() {
  local -ri n="$1"

  repeat "$n"; do
    sleep 1
    time zsh -ic exit 2> /dev/null
  done
}

# Measure zsh start up time and calculate mean time.
zshtimes-stat() {
  local -ri n="$1"

  stdswap zshtimes "$n" \
    | tee >(
        local -F ave=0
        while read; do
          ave+="${${(z)REPLY}[7]}";
        done
        printf "\n  AVG: %f (s)\n" "$((ave / n))"
      )
}

# Zcompile zsh user configures
# Global:
#   None
# Arguments:
#   None
# Return:
#   Compiled zsh user configure names
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

# Proxy for fuzzy finder. Override this function or unset this and add a fuzzy
# finder executable which the name is `fuzzyfinder` to a directory on `PATH` if
# want to use another fuzzy finder.
fuzzyfinder () {
  local -ra ffs=( \
    sk-tmux \
    sk \
    fzf-tmux \
    fzf \
  )

  for ff in "${ffs[@]}"; do
    if has "$ff"; then
      "$ff" "$@"
      return 0
    fi
  done

  error "Not found expected fuzzy finders: ${ffs[@]}"
  return 1
}

# Join arguments as filesystem path.
join_path () {
  setopt LOCAL_OPTIONS EXTENDED_GLOB

  local joined="${1%%\/##}"
  shift

  while [[ $# != 0 ]]; do
    local p="$1"
    shift

    p="${p##\/##}"
    p="${p%%\/##}"
    joined="${joined}/${p}"
  done

  echo "$joined"
}

# Shell function version of xargs, but this can get one argument from stdin
# like a xargs passed `-x -n 1` options. So this name is `xarg` but not
# `xargs`.
#
# NOTE: This can run shell function and builtin command because this is shell
# function but not `xargs` which is standalone executable.
xarg () {
  # Close stdin file descriptor explicitly to suppress a error message from
  # zinit. The error messaage is like this.
  #
  #   @zinit-scheduler:4: failed to close file descriptor 22: bad file descriptor
  #
  "$@" "$(<&0)" 0>&-
}

# Read path from stdin and change directory to the path which is joined with
# prefix. The prefixes are passed as function arguments.
cd_stdin() {
  xarg join_path "$@" | xarg builtin cd
}

__cd_to_git_repository() {
  setopt LOCAL_OPTIONS PIPE_FAIL

  local repo

  # NOTE: Must split a selector step and cd one from single pipe line if no
  # guard about no selection on fuzzy finder because maybe cause cd to ghq root
  # unintentionally.
  ghq list \
    | fuzzyfinder \
        --no-multi \
        --tiebreak=end,length,index \
        --query="$*" \
        --select-1 \
    | { repo="$(<&0)" }

  local -ri exit_code="$?"

  if [[ ${#repo} != 0 ]]; then
    join_path "$(ghq root)" "$repo" | xarg builtin cd
  fi

  return "$exit_code"
}

docker-rmif () {
  local -a images

  docker images --all \
    | fuzzyfinder \
        --multi \
        --header-lines=1 \
    | while read; do echo "${${(z)REPLY}[3]}"; done \
    | { images=($(<&0)) } \
    ;

  if [[ "${#images[@]}" != 0 ]]; then
    docker rmi "$@" "${images[@]}"
  fi
}

docker-rmf () {
  local -a containers

  docker container ls --all \
    | fuzzyfinder \
        --multi \
        --header-lines=1 \
    | while read; do echo "${${(z)REPLY}[1]}"; done \
    | { containers=($(<&0)) } \
    ;

  if [[ "${#containers[@]}" != 0 ]]; then
    docker rm "$@" "${containers[@]}"
  fi
}

__run-help-tmux-pane() {
  local -r CMD="${(qqq)LBUFFER}"

  if [[ -n "${TMUX_PANE}" ]]; then
    tmux split-window "man ${CMD}"
  else
    man "${CMD}"
  fi
}

# Make a directory which it's name is current date and time.
# Global:
#   None
# Arguments:
#   None
# Return:
#   None
mkdir-datetime() {
  mkdir "$(datetime)"
}

# Whether or not current working directory is git root.
__is_at_git_root () {
  [[ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" == true ]]
}

# Apply Oceanic-Nect color scheme for Linux Console.
# Global:
#   None
# Arguments:
#   None
# Return:
#   None
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

# Run a process in the background and no output to stdout and stderr.
# Global:
#   None
# Arguments:
#   ARGS: Command name and the arguments.
# Return:
#   None
__run_in_background() {
  # A way to run a command in the background and not to output some strings to
  # stdout and stderr is to run `cmd > /dev/null 2>&1`. But this way outputs to
  # stdout and stderr to show, that moving a process into the background and
  # completing a process, to a parent shell. So to prevent this problem use sub
  # shell and redirects the stdout and stderr to /dev/null.
  (eval "${*}" &) &> /dev/null
}

# Map a keybinding to a function using ZLE.
#
# 1. Create user defined widget.
# 2. Bind a key combination to the widget.
#
# Global:
#   None
# Arguments:
#   keys: key combinations
#   fun: function name
# Return:
#   None
bind_key2fun () {
  local -r keys="$1"
  local -r fun="$2"

  zle -N "$fun"
  bindkey "$keys" "$fun"
}

manual_description2query() {
  setopt localoptions extended_glob

  local -r query="${1/ ##-*/}"

  # Valid patterns
  # - Linux
  #   - '1' 'cmd'
  #   - 'cmd(1)'
  #   - 'cmd.1'
  # - macOS
  #   - '1' 'cmd'
  case "$query" in
    *,* )
      # This format may cause on macOS.
      # i.g. command(1), commandor(1)
      manual_description2query "${query/,*/}"
      ;;
    *\ \(* )
      # i.g. command (1)
      # NOTE: Assume `queries`'s length is 2 and first element is command name,
      # second element is section number.
      local -ra queries=(${(@s: :)query})
      echo "${queries[2]//[()]/} ${queries[1]}"
      ;;
    *\(* )
      # This format may cause on macOS.
      # i.g. command(1)
      manual_description2query "${query/\(/ (}"
      ;;
    * )
      echo "$query"
      ;;
  esac
}

# Show GitHub contributions, which is called `kusa` by Japanese.
kusa () {
  local -r username="$(command git config user.name)"

  curl "https://github-contributions-api.deno.dev/${username}.term"
}

ipinfo () {
  curl ipinfo.io
}

# Wrap text with two arguments.
# Global:
#   None
# Arguments:
#   left: Left delimiter.
#   right: Right delimiter.
# Return:
#   Wrapped text with arguments.
wrap() {
  echo -n "$1$(<&0)$2"
}

ghq-exist () {
  local -i verbose=0
  local query=''

  while [[ $# > 0 ]]; do
    case "$1" in
      -v | --verbose )
        verbose=1
        shift
        ;;
      * )
        query="$1"
        shift
        ;;
    esac
  done

  __print () {
    if [[ "$verbose" == 0 ]]; then
      return 0
    fi

    echo "$@"
  }

  __info () {
    __print "$@" >&2
  }

  local -a repos
  command ghq list --full-path --exact "$query" | { repos=($(<&0)) }

  case "${#repos}" in
    0 )
      error 'Not found matching repository.'
      return 1
      ;;
    1 )
      __info 'Exist unique repository.'
      __print "${repos[1]}"
      return 0
      ;;
    * )
      warning "Found some ambiguous repositories."
      __print "${(F)repos}"
      return 1
      ;;
  esac
}

ghq-cd () {
  local -r query="$1"

  local -a repos
  ghq-exist --verbose "$query" | { repos=($(<&0)) }

  if [[ "${#repos[@]}" == 1 ]]; then
    # NOTE: `cd ''` means `cd .`.
    builtin cd "${repos[1]}"
  fi
}

# Template generator for sub command proxy.
subcommand_wrapper_def () {
  local -r cmd="$1"

  echo "$cmd" '() {
    local cmd="$0"

    local -r sub="$1"
    local -r sub_command="${cmd}-${sub}"

    if has "$sub_command"; then
      shift
      "$sub_command" "${@}"
    else
      command "$cmd" "${@}"
    fi
  }'
}

# Generate proxy command for user defined custom command. If want to add custom
# sub command `sub` to `cmd` call `generate_subcommand_wrapper cmd` and add
# something command named `cmd-sub`. It is allowed as a standalone executable,
# a shell function and an alias. By this we can call the sub command with
# `cmd sub`.
#
# NOTE: What? Do you think that it is enough to call `cmd-sub` directly? Me
# too. Maybe need to add something useful to argue merit.
# NOTE: This system is inspired by `git`.
generate_subcommand_wrapper () {
  local -r cmd="$1"

  has "$cmd" && eval "$(subcommand_wrapper_def "$cmd")"
}

generate_subcommand_wrapper docker
generate_subcommand_wrapper ghq


# Proxy function for ls on chpwd.
__chpwd_ls () {
  l
}

# Proxy function for git status on chpwd.
__chpwd_git_status () {
  if __is_at_git_root; then
    echo
    git status --short --branch
  fi
}
# }}}

# Hook functions {{{
chpwd() {
  __chpwd_ls
  __chpwd_git_status
}
# }}}

# Widgets {{{
__fuzzy_history_select() {
  setopt LOCAL_OPTIONS PIPE_FAIL

  history -r 1 \
    | fuzzyfinder \
        --no-multi \
        --nth=2..,.. \
        --tiebreak=index \
        --query="$LBUFFER" \
    | read -Ee \
    | read -d ' ' num \
    ;

  local -ri exit_code="$?"

  [[ -n "$num" ]] && zle vi-fetch-history -n "$num"
  zle redisplay

  return "$exit_code"
}

# Widget for __absolute_command_path
# Global:
#   path
# Arguments:
#   None
# Return:
#   None
__absolute_command_path_widget() {
  setopt localoptions pipefail 2> /dev/null

  local -r FZF_OPTS="${FZF_DEFAULT_OPTS} --no-multi --tiebreak=end --bind=ctrl-r:toggle-sort --query=${(qqq)LBUFFER}"
  LBUFFER=$(FZF_DEFAULT_OPTS="${FZF_OPTS}" __absolute_command_path)
  local -r EXIT_CODE="${?}"

  zle redisplay
  return "${EXIT_CODE}"
}

__strip_head () {
  setopt localoptions extended_glob

  # Assume that head character of all command line buffer is not whitespaces or
  # newline. This is normalization for following case match.
  LBUFFER="${LBUFFER##[[:IFS:]]##}"

  # e.g. sudo ls path -> ls path
  # | is cursor position
  case "$LBUFFER" in
    # sudo ls path|
    # sudo    |    ls path
    *[[:IFS:]]* )
      LBUFFER="${LBUFFER##[^[:IFS:]]##}"
      LBUFFER="${LBUFFER##[[:IFS:]]##}"
      RBUFFER="${RBUFFER##[[:IFS:]]##}"
      ;;
    # sudo| ls path
    # s|udo     ls path
    # |   sudo ls path
    * )
      LBUFFER=''
      RBUFFER="${RBUFFER##[[:IFS:]]##}"
      RBUFFER="${RBUFFER##[^[:IFS:]]##}"
      RBUFFER="${RBUFFER##[[:IFS:]]##}"
      ;;
  esac

  zle redisplay
}

__fuzzy_select_manual () {
  setopt LOCAL_OPTIONS PIPE_FAIL

  apropos . \
    | fuzzyfinder \
        --no-multi \
        --tiebreak=begin,length \
        --query="$LBUFFER" \
        --preview="$(which manual_description2query); command man \$(manual_description2query {})" \
    | read -r query \
    ;

  local -i exit_code="$?"

  local -ra queries=($(manual_description2query "$query"))
  case "${#queries[@]}" in
    2 )
      command man "${queries[@]}"
      ;;
    0 )
      exit_code=2
      ;;
    * )
      error "Expected values are that first element is section number, second element is command name. But actual values are `${queries[@]}`"
      exit_code=2
      ;;
  esac

  zle redisplay
  return "$exit_code"
}

# Fixed version of backward-kill-word which is recognize also `/` as word
# separators.
# Global:
#   WORDCHARS: See ZSHPARAM(1)
# Arguments:
#   None
# Return:
#   None
#
# NOTE: Maybe this should be global config.
backward_kill_word_and_dir() {
  local WORDCHARS=${WORDCHARS/\/}
  zle backward-kill-word
}
# }}}

# Login shell {{{
if [[ -o LOGIN ]]; then
  # {{{ basic
  export EDITOR=vim
  export VISUAL=vim
  export PAGER=less

  export XDG_CONFIG_HOME=~/.config
  export XDG_CACHE_HOME=~/.cache
  export XDG_DATA_HOME=~/.local/share

  # prevent adding duplication path
  typeset -U path PATH

  add2path ~/.node_modules/bin
  add2path ~/.local/bin
  add2path ~/.cargo/bin
  add2path ~/.ghcup/bin
  add2path ~/.cabal/bin
  add2path ~/bin
  # }}}

  # {{{ man
  export MANOPT='--nj'

  # colorized man with less
  export LESS_TERMCAP_mb=$'\E[01;31m'      # Begins blinking.
  export LESS_TERMCAP_md=$'\E[01;31m'      # Begins bold.
  export LESS_TERMCAP_me=$'\E[0m'          # Ends mode.
  export LESS_TERMCAP_se=$'\E[0m'          # Ends standout-mode.
  export LESS_TERMCAP_so=$'\E[00;47;30m'   # Begins standout-mode.
  export LESS_TERMCAP_ue=$'\E[0m'          # Ends underline.
  export LESS_TERMCAP_us=$'\E[01;32m'      # Begins underline.

  if has vim; then
    # Maybe fail to open man page with vim as pager due to no filetype plugin
    # of vim loaded. Then, there are two ways to resolve this problem.
    #
    # 1. Overwrite the environment variable `MANPAGER` with empty string.
    #   e.g.
    #   $ MANPAGER= man some_command
    #
    # 2. Config vimrc to load filetype plugin.
    #   e.g.
    #   "in vimrc
    #   filetype plugin on
    #
    # NOTE: Supress `Vim: Reading from stdin...` message using `--not-a-term`.
    # https://github.com/vim/vim/commit/234d16286a2733adedef56784c17415ae169b9ad
    export MANPAGER='vim -M +MANPAGER -c "set nolist" --not-a-term -'
  fi
  # }}}

  # {{{ zsh
  # history
  export HISTFILE=~/.zsh_history
  export HISTSIZE=1100000
  export SAVEHIST=1000000

  # spelling correction prompt
  export SPROMPT="zsh: correct: %F{red}%R%f -> %F{green}%r%f [No/Yes/Abort/Edit]? "
  # }}}

  # {{{ other
  export LESS='-ij10FMRX'

  if has fzf; then
    export FZF_DEFAULT_OPTS='--reverse --height=40%'

    if has rg; then
      export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
    fi
  fi

  if has go; then
    export GOPATH=~/go
    add2path "${GOPATH}/bin"
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
    if ! pgrep -x -u "${USER}" ssh-agent &> /dev/null; then
      # Start ssh-agent process and cache the output
      ssh-agent -t ${SSH_KEY_LIFE_TIME_SEC} > "${SSH_AGENT_ENV}"
    fi

    # When not loading ssh-agent process information
    if [[ -f "${SSH_AGENT_ENV}" && ! -v SSH_AUTH_SOCK && ! -v SSH_AGENT_PID ]]; then
      source "${SSH_AGENT_ENV}" &> /dev/null
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
  if is_linux; then
    export TERMINAL="$(__default_terminal)"
    export BROWSER="$(__default_browser)"

    __enable_ssh_agent
    __run_in_background __start_dropbox
  fi
  # }}}

  # Plugin configures {{{
  export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  export PURE_PROMPT_SYMBOL=λ
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

alias e="${EDITOR}"
alias v=vim
alias vw=view
alias dk=docker
alias dkcp=docker-compose
alias dkcpe='dkcp exec'
alias g=git
alias t=tig
alias tiga='tig --all'
alias a=tiga
alias p=pipenv
alias fzfd='FZF_DEFAULT_COMMAND="find . -type d" fzf'
alias m=man

alias c=__cd_to_git_repository
alias cdh='cd ~'
alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'
alias shinit='exec ${SHELL}'
alias zshinit='zshcompiles &> /dev/null && shinit'
alias z=zshinit
alias q=exit
alias qq=q
alias qqq=q
alias quit=q
alias :q=q

if is_linux; then
  alias open=xdg-open
  alias op='__run_in_background open'
  alias ff=firefox
  alias xc='xclip -selection clipboard -filter -rmlastnl && echo'
  alias lb='lsblk -o NAME,FSTYPE,FSVER,FSSIZE,FSUSED,FSAVAIL,FSUSE%,PARTTYPENAME,MOUNTPOINT'
  alias ip='ip -color=auto'
  alias x=startx
  alias xr=xrandr
elif is_macos; then
  alias op=open
fi

# void loop
alias vloop='while [[ 1 ]] {}'
alias vloop2='yes > /dev/null'

# Current date and time.
alias datetime="date +'%Y%m%d%H%M%S'"
# Date only version of datetime.
alias date2="datetime | cut -c -8"

alias hl='haskellorls --color=auto --extra-color --icons -ABFhvo'
# }}}

# Zstyle {{{
zstyle ':completion:*' completer _expand _complete _match _approximate _list
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z-_}={A-Za-z_-}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors \
  'fi=' \
  'di=01;34' \
  'ln=01;36' \
  'pi=33' \
  'so=01;35' \
  'bd=01;33' \
  'cd=01;33' \
  'mi=' \
  'or=' \
  'ex=01;32' \
  'do=01;35' \
  'su=37;41' \
  'sg=30;43' \
  'st=37;44' \
  'ow=34;42' \
  'tw=30;42' \
  'ca=30;41' \
  'mh=' \
  ;
# }}}

# Key bindings {{{
bindkey -e

zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

bind_key2fun '^R' __fuzzy_history_select
bind_key2fun '^x^p' __absolute_command_path_widget
bind_key2fun '^X^A' __strip_head
bind_key2fun '^X^M' __fuzzy_select_manual
bind_key2fun '^[h' backward_kill_word_and_dir

# Delete a forward char with a `delete` key.
bindkey '^[[3~' delete-char

# No need to list possible completions even if command line buffer is empty.
bindkey '^D' delete-char
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
  wait lucid atclone"dircolors -b LS_COLORS > c.zsh" atpull'%atclone' pick"c.zsh" has"dircolors" atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' \
    trapd00r/LS_COLORS \
  pick"async.zsh" src"pure.zsh" \
    sindresorhus/pure \
  ;
# }}}

# sindresorhus/pure {{{
zstyle :prompt:pure:git:stash show yes
# }}}
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
