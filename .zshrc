#
# ~/.zshrc
#
# # Coding Style
#
# ## Nested function prefix
#
# Add prefix to each functions which are defined (nested) in functions. The
# prefix must be parent function name and the name format is `prefix::name`
# like namespace of Ruby. This is for fake namespace.
#
# ## Indirect function prefix
#
# Add `__` as prefix to name of each functions which are for invocation by not
# user. The most frequent situation is ZLE widget.
#
# ## Array Declaration
#
# Separates variable declaration and value assignment for array due to a bug of
# early version of zsh. This is fixed since version `5.1`. See [1].
#
# ## Associative Array Declaration
#
# Separates variable declaration and each value assignment for associative
# array for compatibility of eary version of zsh.
#
# ## References
#
# [1] https://qiita.com/mpyw/items/e9e4c3b872b30c7024ee

# Functions {{{
# Whether or not the variable is defined.
#
# NOTE: An alternate way is to use `-v` option of `[[` but it is introduced
# since 5.3. So maybe it can not use on some old version's zsh. For example zsh
# 5.1 on Ubuntu 16.04.
is_defined () {
  (( ${(P)+${1}} ))
}
# }}}

# zprof {{{
# Profiling of zsh startup process using zprof. Define an environment variable
# ZPROF if want to profile.
#
# $ ZPROF= zsh
#
if is_defined ZPROF; then
  zmodload zsh/zprof && zprof
fi
# }}}

if [[ -r ~/.shrc ]]; then
  emulate sh -c 'source ~/.shrc'
fi

# zsh module {{{
# `module_path` and `MODULE_PATH` in enrionment is ignored for security reason.
# (See the `module_path` section in `ZSHPARAM(1)` for more detail.) So no
# effect even if `export` it and need to add values to it at every shell
# invocation.

zmodload \
  zsh/complist \
  zsh/datetime \
  &>/dev/null \
  ;
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
autoload -Uz \
  add-zsh-hook \
  cdr \
  chpwd_recent_dirs \
  compinit \
  ;

is_linux () {
  [[ "$OSTYPE" =~ '^linux.*' ]]
}

is_macos () {
  [[ "$OSTYPE" =~ '^darwin.*' ]]
}

warning () {
  local prefix= suffix=

  if [[ -t 2 ]]; then
    prefix='\033[33m'
    suffix='\033[0m'
  fi

  if (( $# )); then
    echo $*
  else
    idp
  fi | wrap $prefix $suffix >&2
}

error () {
  local prefix= suffix=

  if [[ -t 2 ]]; then
    prefix='\033[31m'
    suffix='\033[0m'
  fi

  if (( $# )); then
    echo $*
  else
    idp
  fi | wrap $prefix $suffix >&2
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
    path=(
      "$candidate"(N-/)
      "${path[@]}"
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
  (( ${+commands["$1"]} )) || whence "$1" > /dev/null
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
  local -F ave=0

  stdswap zshtimes "$n" \
    | while read; do
        echo "$REPLY"
        ave+="${${(z)REPLY}[7]}"
      done

  printf "\n  AVG: %f (s)\n" "$[ave / n]"
}

# Zcompile zsh user configs.
zshcompiles () {
  local -r zhome=${ZDOTDIR:-~}

  local -a configs
  configs=(
    $zhome/.zshenv
    ~/.local.zshenv
    $zhome/.zprofile
    ~/.local.zprofile
    $zhome/.zshrc
    ~/.local.zshrc
    $zhome/.zlogin
    ~/.local.zlogin
  )

  for c in $configs[@]; do
    xcompile $c
  done
}

# Apply Oceanic-Nect color scheme for Linux Console.
oceanic_next() {
  echo -e "
  \033]P0121c21
  \033]P1e44754
  \033]P289bd82
  \033]P3f7bd51
  \033]P45486c0
  \033]P5b77eb8
  \033]P650a5a4
  \033]P7ffffff
  \033]P852606b
  \033]P9e44754
  \033]PA89bd82
  \033]PBf7bd51
  \033]PC5486c0
  \033]PDb77eb8
  \033]PE50a5a4
  \033]PFffffff
  "
  # get rid of artifacts
  clear
}

# Run a process in the background and no output to stdout and stderr.
runb () {
  "$@" &> /dev/null &|
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

# Convert manual description to arguments of `man`.
man2args() {
  # Expected input form.
  #
  # - "command (1)"
  # - "command(1)"
  # - "command(1), cmd(1)"
  #
  # NOTE: These last two formats may cause on macOS.
  echo ${(Oa)${(z)${1//[()]/ }}[1,2]}
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
  echo "${1}$(idp)${2}"
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
      "$sub_command" "$@"
    else
      command "$cmd" "$@"
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

# Compile file if only source file is newer than .zwc (compiled file).
# Lightweight version of zrecompile.
xcompile () {
  local -r src=${1%.zwc}
  local -r zwc=$src.zwc

  # Compile outdated zwc.
  # NOTE: This conditional contains also file existance check.
  if [[ $src -nt $zwc ]]; then
    zcompile $src
  fi
}

# Source an external file with useful extra.
xsource () {
  local -r src="$1"

  [[ -r "$src" ]] || return 1

  xcompile "$src"

  builtin source "$src"
}

prof () {
  local -r viewer="${PAGER:-idp}"
  ZPROF= zsh -i -c "zprof | ${viewer}"
}

# Identity mapping to use as a part of pipeline.
idp () {
  if has is-at-least && is-at-least 5.2; then
    # NOTE: Somehow `read` waits forever in early version (>= 5.1.1) of zsh.
    # So in such situation use `while read` instead of `read -d ''` as
    # fallback.
    # NOTE: `read -d '' -e` is so naive, doesn't have no good buffering, and
    # doesn't output until read all inputs. It is a bit faster than `while
    # read` but maybe we feel it as no responsively when treat large input.
    # NOTE: `read` with `-d ''` option always returns 1 as exit code.
    read -d '' -e -r || true
  else
    # NOTE: Set $'\n' to IFS explicitly to get whitespaces at line's head.
    local IFS=$'\n'

    # NOTE: `while read -e -r {}` outputs an extra empty line at the end.
    while read -r; do print -r -- $REPLY; done
  fi
}

# Check whether or not commands are found on command line.
check () {
  local -i exit_code=0

  while (( $# )); do
    if ! has $1; then
      error "$0: Not found the command '$1'"
      exit_code=1
    fi

    shift
  done

  return $exit_code
}

sshagent () {
  if ! is_linux; then
    warning <<EOF
This assumes to be called on Linux. Override 'OSTYPE' environment variable to
'linux*' and call this if wanna call this forcely.

  $ OSTYPE=linux sshagent

EOF
    return 1
  fi

  if ! check ssh-agent; then
    return 1
  fi

  sshagent::help () {
    echo -n "\
Description:
  Simple utility for ssh-agent. The main purpose of this is to run ssh-agent
  with a guard on Linux.

Usage:
  sshagent [-f] [-k] [-t <seconds>]

Options:
  -f, --force               Force run ssh-agent even if one has been already run.
  -k, --kill                Kill an ssh-agent specified by 'SSH_AGENT_PID'.
  -t, --lifetime=seconds    Specify a lifetime (seconds) of key id for ssh-agent.
  -h, --help                Show this message.
"
  }

  local -i force=0
  local -i kill=0
  # 1h = 60s * 60m
  local -i lifetime=3600

  while (( $# )); do
    case $1 in
      -h | --help )
        sshagent::help
        return 0
        ;;
      -k | --kill )
        kill=1
        shift
        ;;
      -t )
        lifetime=$2
        shift 2
        ;;
      --lifetime=* )
        lifetime=${1#--lifetime=}
        shift
        ;;
      -f | --force )
        force=1
        shift
        ;;
      * )
        error "$0: Invalid option '$1'"
        return 1
        ;;
    esac
  done

  if (( kill )); then
    eval "$(ssh-agent -k)"
    return
  fi

  if is_defined SSH_AUTH_SOCK && is_defined SSH_AGENT_PID && ! (( force )); then
    warning 'A ssh-agent process for this shell has already running.'
    return 1
  fi

  eval "$(ssh-agent -t $lifetime)"
}
# }}}

# Custom subcommands {{{
# ghq {{{
ghq-find () {
  command ghq list --full-path --exact "$1"
}

ghq-exist () {
  local -i verbose=0
  local query=''

  while [[ "$#" > 0 ]]; do
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
  ghq-find "$query" | { repos=( ${(f)"$(read -d '' -e)"} ) }

  case "${#repos[@]}" in
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
      __print "${(F)repos[@]}"
      return 1
      ;;
  esac
}

ghq-cd () {
  local query=''
  local -a args

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -q )
        args+=('-q')
        shift
        ;;
      * )
        query="$1"
        shift
        ;;
    esac
  done

  local -a repos
  ghq-find "$query" | { repos=( ${(f)"$(read -d '' -e)"} ) }

  if [[ "${#repos[@]}" == 1 ]]; then
    # NOTE: `cd ''` means `cd .`.
    builtin cd "${args[@]}" "${repos[1]}"
  else
    return 1
  fi
}

ghq-update () {
  local -a queries
  local -i all=0

  ghq-update::help () {
    echo -n "\
Update ('fetch' in fact) all git repositories which match each queries.

Usage:
  ghq update [-a | --all] [[query]...]

Options:
  -a, --all     Update all repositories under ghq control.
  -h, --help    Show this message.
"
  }

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -a | --all )
        all=1
        shift
        ;;
      -h | --help )
        ghq-update::help
        return
        ;;
      * )
        queries+=("$1")
        shift
        ;;
    esac
  done

  if (( all )); then
    queries=($(ghq list))
  fi

  for query in "${queries[@]}"; (
    if ghq-cd -q "$query"; then
      echo "  Update: ${query}"
      command git remote update
    else
      error "Not found a unique repository in local to match '${query}'"
    fi
  )
}
# }}}
# }}}

# Widgets {{{
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

# Proxy to call `exit` from as ZLE.
__quit () { exit }
# }}}

# Login shell {{{
if [[ -o LOGIN ]]; then
  [[ "$TERM" == "linux" ]] && oceanic_next

  if is_linux; then
    sshagent &>/dev/null
  fi
fi
# }}}

# Parameters {{{
# History.
HISTFILE=~/.zsh_history
HISTSIZE=1100000
SAVEHIST=1000000

# Treat also slash(/) as word separater.
WORDCHARS="${WORDCHARS/\//}"

PS1='
%F{cyan}%~%f%(?.. %B%F{red}%?%f%b)%1(j. %F{yellow}%B%j%bj%f.) Lv.%L %F{magenta}%D{%H:%M:%S} %D%f
%(?.%F{green}.%F{red})%#%f '

# Spelling correction prompt.
SPROMPT="zsh: correct: %F{red}%R%f -> %F{green}%r%f [No/Yes/Abort/Edit]? "

# Report.
REPORTTIME=1
REPORTMEMORY=1000
TIMEFMT+=' max RSS %MKB'

# Others.
watch=(notme)
# }}}

# Aliases {{{
alias zshinit='zshcompiles && shinit'
alias z=zshinit

# NOTE: Use '-rC1' and '--' options instead of '-l' to print every arguments
# separated by newline. This is more robust way about following three points.
#
# 1. Raw literal printing even if contains escaped characters.
# 2. Empty output if no argument.
# 3. Explicit arguments even if they start with hyphen.
#
# See '-l' option and other of 'print' in zshbuiltins (1) for more detail. But
# maybe no need this to print $path because almost $path doesn't be empty and
# almost their elements don't contain escaped characters and don't start with
# hyphen.
alias path='print -rC1 -D -- $path'
# }}}

# Zstyle {{{
zstyle ':chpwd:*' recent-dirs-max 0
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

bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# Pure zsh widgets.
bind_key2fun '^X^A' __strip_head
bind_key2fun '^X^E' __quit

bindkey '^R' history-incremental-pattern-search-backward
bindkey '^S' history-incremental-pattern-search-forward

# Delete a forward char with a `delete` key.
bindkey '^[[3~' delete-char

# No need to list possible completions even if command line buffer is empty.
bindkey '^D' delete-char
# }}}

# Others {{{
compinit

add-zsh-hook chpwd chpwd_recent_dirs

generate_subcommand_wrapper ghq

xsource ~/.local.zshrc
xcompile ~/.zshrc
# }}}

# vim: set foldmethod=marker :
