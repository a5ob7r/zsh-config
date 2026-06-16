#
# ~/.zshrc
#
# - The minimal requirement version is 5.8.1 (installed in macOS v12.7.6 by default).
#

# For prof().
if (( ${+ZPROF} )); then
  zmodload zsh/zprof && zprof
fi

if [[ -r ~/.shrc ]]; then
  emulate sh -c 'source ~/.shrc'
fi

zmodload zsh/complist

# ZSHOPTIONS {{{
setopt CORRECT
setopt EXTENDED_GLOB
setopt EXTENDED_HISTORY
setopt HIST_EXPAND
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_VERIFY
setopt LIST_PACKED
setopt LONG_LIST_JOBS
setopt MAGIC_EQUAL_SUBST
setopt MARK_DIRS
setopt PRINT_EXIT_VALUE
setopt PROMPT_SUBST
setopt SHARE_HISTORY

unsetopt BEEP
unsetopt FLOW_CONTROL
# }}}

# Functions {{{
warning () {
  echo -e '\033[33m'$*'\033[0m' >&2
}

error () {
  echo -e '\033[31m'$*'\033[0m' >&2
}

has() {
  whence $1 > /dev/null
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

prof () {
  local -r pager=${PAGER:-less}

  if has $pager; then
    local -r command="zprof | $pager"
  else
    local -r command=zprof
  fi

  ZPROF= zsh -i -c $command
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

autoload -Uz compinit; compinit

if [[ -r ~/.local.zshrc ]]; then
  source ~/.local.zshrc
fi

# vim: set foldmethod=marker :
