#
# ~/.zshrc
#

# zprof {{{
# Profiling of zsh startup process using zprof. Define an environment variable
# ZPROF if want to profile.
#
# $ ZPROF= zsh
#
# NOTE: Wanna use `-v` option of `[[` to check whether or not `ZPROF` is
# declared but it is introduced since 5.3. So maybe it can not use on some old
# version's zsh. For example zsh 5.1 on Ubuntu 16.04.
if (( ${+ZPROF} )); then
  zmodload zsh/zprof && zprof
fi
# }}}

# zsh module {{{
# `module_path` and `MODULE_PATH` in enrionment is ignored for security reason.
# (See the `module_path` section in `ZSHPARAM(1)` for more detail.) So no
# effect even if `export` it and need to add values to it at every shell
# invocation.

# Zinit module to compile sourced files, which contains plugins, automatically.
# Build the module to use it by run `zinit module build`.
if [[ -x ~/.zinit/bin/zmodules/Src/zdharma/zplugin.so ]]; then
  module_path+=( ~/.zinit/bin/zmodules/Src(N/) )
fi

zmodload \
  zdharma/zplugin \
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
autoload -Uz \
  add-zsh-hook \
  cdr \
  chpwd_recent_dirs \
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
  (( ${+commands["$1"]} )) || whence "$1" > /dev/null
}

# Search that whether or not a command is made by GNU
# Global:
#   None
# Arguments:
#   1: A command name
# Return:
#   0 or 1: Whether or not a command is made by GNU
gnu() {
  "$1" --version 2>&1 | grep -q GNU
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

# List full pathes of all executables on $path.
executables () {
  setopt LOCAL_OPTIONS EXTENDED_GLOB
  which "${^path[@]%%/##}"/*(N-*) || true
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

  # Zcompile zsh user configure and local it
  # Global:
  #   None
  # Arguments:
  #   1: Zsh configure path
  # Return:
  #   Compiled zsh user configure names
  zsh_compile() {
    local -ra CONFIGS=( \
      "$1" \
      "${1}.local" \
    )

    for c in "${CONFIGS[@]}"; do
      if [[ -f "$c" ]]; then
        zcompile "$c"
        echo "Compiled: ${c}"
      fi
    done
  }

  for zc in "${ZSH_CONFIGS[@]}"; do zsh_compile "$zc"; done
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
  "$@" "$(read -d '' -e)"
}

__run-help-tmux-pane() {
  local -r CMD="${(qqq)LBUFFER}"

  if [[ -n "$TMUX_PANE" ]]; then
    tmux split-window "man ${CMD}"
  else
    man "$CMD"
  fi
}

# Whether or not current working directory is git root.
__is_at_git_root () {
  [[ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" == true ]]
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
  echo "${1}$(read -d '' -e)${2}"
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

cdrf () {
  setopt LOCAL_OPTIONS PIPE_FAIL

  cdr -l \
    | fuzzyfinder \
        --nth='2..' \
        --no-multi \
        --tiebreak='end,index' \
        --query="${*}" \
    | read -r -d ' ' idx \
    ;

  local -ri exit_code="$?"

  [[ -n "$idx" ]] && cdr "$idx"

  return "$exit_code"
}

# Compile file if only source file is newer than .zwc (compiled file)
xcompile () {
  local -r src="$1"
  local -r zwc="${src}.zwc"

  [[ "$src" -ot "$zwc" ]] || zcompile "$src"
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

# Identity mapping to use as a part of pipeline. This is a bare alternate of
# `cat -` but pure zsh function.
idp () {
  # `read` with `-d ''` option always returns 1 as exit code.
  read -d '' -e || true
}

init_zinit () {
  local -r src=~/.zinit/bin/zinit.zsh

  if [[ ! -r $src ]]; then
    warning "Not found '$src' and 'zinit' has not been installed yet so try to install it."

    if ! check curl git sh; then
      error 'Requirements are not installed. Try it again after install them.'
      return 1
    fi

    curl -fsSL 'https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh' | sh
  fi

  xsource $src
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

# Whether or not the variable is defined.
is_defined () {
  (( ${(P)+${1}} ))
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

  help () {
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
        help
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

# NOTE: Optional. Call it on local config if wanna start dropbox.
start_dropbox () {
  help () {
    echo -n "\
Description:
  Simple utility to run dropbox on Linux.

Usage:
  start_dropbox

Options:
  -h, --help    Show this message and exit.
"
  }

  case $1 in
    -h | --help )
      help
      return 0
      ;;
  esac

  if ! is_linux; then
    warning "$0: This assumes to be run on Linux."
    return 1
  fi

  if ! has dropbox; then
    return 1
  fi

  if ! has pgrep; then
    error "$0: Can not detect whether or not dropbox has been already running."
    return 1
  fi

  if pgrep dropbox &>/dev/null; then
    warning "$0: A dropbox process has already been running."
    return 0
  fi

  if has dropbox-cli; then
    dropbox-cli start && dropbox-cli lansync n
  else
    dropbox
  fi
}
# }}}

# Custom subcommands {{{
# docker {{{
docker-rmif () {
  local -a images

  docker images --all \
    | fuzzyfinder \
        --multi \
        --header-lines=1 \
    | while read; do echo "${${(z)REPLY}[3]}"; done \
    | { images=( ${(f)"$(read -d '' -e)"} ) } \
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
    | { containers=( ${(f)"$(read -d '' -e)"} ) } \
    ;

  if [[ "${#containers[@]}" != 0 ]]; then
    docker rm "$@" "${containers[@]}"
  fi
}
# }}}

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
  local -a args=()

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

ghq-cdf () {
  local repo

  # NOTE: Must split a selector step and cd one from single pipe line if no
  # guard about no selection on fuzzy finder because maybe cause cd to ghq root
  # unintentionally.
  ghq list --full-path \
    | fuzzyfinder \
        --no-multi \
        --tiebreak=end,length,index \
        --query="$*" \
        --select-1 \
    | { read -d '' repo }

  if [[ ${#repo} != 0 ]]; then
    builtin cd "$repo"
  else
    return 1
  fi
}

ghq-update () {
  local -a queries=()
  local -i all=0

  help () {
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
        help
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

# All executables fuzzy selector.
__fuzzy_executables_select () {
  setopt LOCAL_OPTIONS PIPE_FAIL 2> /dev/null

  executables \
    | fuzzyfinder \
        --no-multi \
        --query="${LBUFFER}${RBUFFER}" \
    | read cmd \
    ;

  local -ri exit_code="$?"

  if [[ "$exit_code" == 0 ]]; then
    LBUFFER="$cmd"
    RBUFFER=''
  fi

  zle redisplay
  return "$exit_code"
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
      error "Expected values are that first element is section number, second element is command name. But actual values are '${queries[@]}'"
      exit_code=2
      ;;
  esac

  zle redisplay
  return "$exit_code"
}

# Proxy to call `exit` from as ZLE.
__quit () { exit }

# Interactive cdr using fuzzy finder as ZLE widget.
__cdrf () {
  setopt LOCAL_OPTIONS PIPE_FAIL

  local -i idx

  cdr -l \
    | fuzzyfinder \
        --nth='2..' \
        --no-multi \
        --tiebreak='end,index' \
        --query="$BUFFER" \
    | read -r -d ' ' idx \
    ;

  local -ri exit_code="$?"

  if [[ "$exit_code" == 0 && -n "$idx" ]]; then
    # NOTE: Need to rewrite buffer and to use `accept-line` to change directory
    # using cdr on ZLE widget. Somehow it does not work correctly if call `cdr`
    # directly on ZLE widget. It changes current working directory to different
    # one which is not selected by fuzzy finder. Why?
    BUFFER="cdr ${idx}"
    zle accept-line
  else
    zle redisplay
  fi
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
    #
    # NOTE: Maybe it is enough to pass `-M` option to vim instead of
    # `-c "set nomodifiable | set nowrite"` in accordance with the document.
    # But somehow no effect even if passes `-M`. Is this bug?
    export MANPAGER='vim +MANPAGER -c "set nolist | set nomodifiable | set nowrite" --not-a-term -'
  fi
  # }}}

  # {{{ zsh
  # history
  export HISTFILE=~/.zsh_history
  export HISTSIZE=1100000
  export SAVEHIST=1000000

  # Treat also slash(/) as word separater.
  export WORDCHARS="${WORDCHARS/\//}"

  # spelling correction prompt
  export SPROMPT="zsh: correct: %F{red}%R%f -> %F{green}%r%f [No/Yes/Abort/Edit]? "
  # }}}

  # {{{ other
  export LESS='-ij10FMRX'

  export FZF_DEFAULT_OPTS='--reverse --height=40%'

  if has rg; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
  fi

  if has go; then
    export GOPATH=~/go
    add2path "${GOPATH}/bin"
  fi

  export PIPENV_VENV_IN_PROJECT=1

  export RUSTFLAGS='-C target-cpu=native'

  export path

  [[ "$TERM" == "linux" ]] && oceanic_next

  if is_linux; then
    sshagent &>/dev/null
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

alias e="$EDITOR"
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

alias c='ghq cdf'
alias cdh='cd ~'
alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'
alias shinit='exec "$SHELL"'
alias zshinit='zshcompiles &> /dev/null && shinit'
alias z=zshinit
alias q=exit
alias qq=q
alias qqq=q
alias quit=q
alias :q=q

if is_linux; then
  alias open=xdg-open
  alias op='runb open'
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

alias datetime="strftime '%Y%m%d%H%M%S'"
# Date only version of datetime.
alias date2="strftime '%Y%m%d'"

alias hl='haskellorls --color=auto --extra-color --icons -ABFhvo'
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

bind_key2fun '^R' __fuzzy_history_select
bind_key2fun '^x^p' __fuzzy_executables_select
bind_key2fun '^X^A' __strip_head
bind_key2fun '^X^M' __fuzzy_select_manual
bind_key2fun '^X^E' __quit
bind_key2fun '^J' __cdrf
bind_key2fun '^X^J' __cdrf

# Delete a forward char with a `delete` key.
bindkey '^[[3~' delete-char

# No need to list possible completions even if command line buffer is empty.
bindkey '^D' delete-char
# }}}

# Plugins {{{
declare -A ZINIT
ZINIT[COMPINIT_OPTS]=-C
ZINIT[OPTIMIZE_OUT_DISK_ACCESSES]=1

init_zinit && zinit light-mode for \
  wait lucid blockf \
    zsh-users/zsh-completions \
  wait lucid atinit'zicompinit; zicdreplay' \
    zdharma/fast-syntax-highlighting \
  wait lucid compile'{src/*.zsh,src/strategies/*.zsh}' atload'_zsh_autosuggest_start' \
    zsh-users/zsh-autosuggestions \
  wait lucid atclone'dircolors -b LS_COLORS > c.zsh' atpull'%atclone' pick'c.zsh' has'dircolors' atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' \
    trapd00r/LS_COLORS \
  pick'async.zsh' src'pure.zsh' atload'zstyle :prompt:pure:git:stash show yes' \
    sindresorhus/pure \
  ;
# }}}

# Others {{{
add-zsh-hook chpwd __chpwd_ls
add-zsh-hook chpwd __chpwd_git_status
add-zsh-hook chpwd chpwd_recent_dirs

generate_subcommand_wrapper docker
generate_subcommand_wrapper ghq

xsource ~/.zshrc.local
xcompile ~/.zshrc
# }}}

# vim: set foldmethod=marker :
