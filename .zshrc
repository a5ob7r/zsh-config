#
# ~/.zshrc
#
# - The minimal requirement version is 5.8.1 (installed in macOS v12.7.6 by default).
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
  echo -e '\033[33m'$*'\033[0m' >&2
}

error () {
  echo -e '\033[31m'$*'\033[0m' >&2
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

# Source an external file with useful extra.
xsource () {
  local -r src="$1"

  [[ -r "$src" ]] || return 1

  builtin source "$src"
}

prof () {
  local -r pager=${PAGER:-less}

  if has $pager; then
    local -r command="zprof | $pager"
  else
    local -r command=zprof
  fi

  ZPROF= zsh -i -c $command
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
# }}}

# Custom subcommands {{{
# ghq {{{
ghq-find () {
  command ghq list --full-path --exact "$1"
}

ghq-cd () {
  setopt LOCAL_OPTIONS ERR_RETURN

  case $# in
    0 )
      error 'ghq-cd: Require one argument.'
      return 1
      ;;
    1 )
      ;;
    * )
      error 'ghq-cd: Too many arguments.'
      return 1
      ;;
  esac

  local -a repositories
  repositories=("${(f)$(ghq-find $1)}")

  case ${#repositories[@]} in
    0 )
      error 'ghq-cd: No repository was found.'
      return 1
      ;;
    1 )
      builtin cd ${repositories[@]}
      ;;
    * )
      error 'ghq-cd: Multiple repositories were found.'
      return 1
      ;;
  esac
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
# }}}

# Login shell {{{
if [[ -o LOGIN ]]; then
  [[ "$TERM" == "linux" ]] && oceanic_next
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
REPORTMEMORY=131072 # 1024 * 128 KB
TIMEFMT+=' max RSS %MKB'

# Others.
watch=(notme)
# }}}

# Aliases {{{
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

xsource ~/.local.zshrc
# }}}

# vim: set foldmethod=marker :
