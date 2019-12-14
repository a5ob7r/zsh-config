# zshrc
#
# 1. shell functions
# 2. environment variables
# 3. aliases
# 4. zstyle
# 5. options
# 6. fzf
# 6. hook
# 7. zplugin

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
  local -r CMD=${1}

  ${CMD} --version 2>&1 | grep -q GNU
}

alias gnu='__is_gnu_coreutils'

__list_path() {
  tr ' ' '\n' <<< "${path}"
}

alias path=__list_path

fghq() {
  local ghq_root
  ghq_root=$(ghq root)

  local repo
  repo=$(ghq list | fzy) || return 1

  cd "$ghq_root/$repo" || return 1
}

fdkrmi() {
  local images
  images=$(docker images | fzf-tmux --multi --header-lines=1) &&
    echo "$images" | awk '{print $3}' | xargs docker rmi
}

fdkrm() {
  local containers
  containers=$(docker container ls -a | fzf-tmux --multi --header-lines=1) &&
    echo "$containers" | awk '{print $1}' | xargs docker rm
}

zshtimes() {
  local -ir NB_TIMES=${1}

  repeat "${NB_TIMES}"; do
    sleep 1
    time (zsh -ic exit)
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


# {{{ Process for login shell
if [[ "$0" == -* ]]; then
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
  export FZF_DEFAULT_OPTS='--reverse'
  if has rg; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
  fi
  export FZF_TMUX=1
  # }}}

  # {{{ anyenv
  __anyenv_init() {
    local -r ANYENV_ROOT=~/.anyenv
    local -r ANYENV_INIT_PATH=~/.config/anyenv/ANYENV_INIT.env

    if [[ ! -d "${ANYENV_ROOT}" ]]; then
      return
    fi

    export ANYENV_ROOT
    add2path ~/.anyenv/bin

    [[ -f "${ANYENV_INIT_PATH}" ]] \
      || anyenv init - --no-rehash  > "${ANYENV_INIT_PATH}"

    source "${ANYENV_INIT_PATH}"
  }
  __anyenv_init
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
fi
# }}}

if gnu grep; then
  alias grep='grep --color=auto'
  alias gr="grep -F -irn --exclude-dir='.git'"
fi

# define alias of colorful and detail ls
if has exa; then
  alias l='exa -la'
  alias lg='l -g'
  alias ll='exa -1'
elif gnu ls; then
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

alias cdh='cd ~'
alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'
alias shinit='exec $SHELL -l'

if [[ -n "${TMUX}" ]] && has anyenv; then
  source ~/.anyenv/completions/anyenv.zsh
  for env in ~/.anyenv/envs/*; do
    source "${env}"/completions/*.zsh
  done
fi

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

! [[ -d ~/.zplugin ]] && \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zplugin/master/doc/install.sh)"

source ~/.zplugin/bin/zplugin.zsh

# If you place the source below compinit,
# then add those two lines after the source:
#autoload -Uz _zplugin
#(( ${+_comps} )) && _comps[zplugin]=_zplugin

zplugin ice blockf
zplugin light 'zsh-users/zsh-completions'
zplugin light 'zsh-users/zsh-autosuggestions'

zplugin light 'zdharma/fast-syntax-highlighting'

zplugin ice pick"async.zsh" src"pure.zsh"
zplugin light 'sindresorhus/pure'

zplugin light 'b4b4r07/enhancd'

if has dircolors; then
  zplugin ice atclone"dircolors -b LS_COLORS > c.zsh" atpull'%atclone' pick"c.zsh"
  zplugin light trapd00r/LS_COLORS
fi

autoload -Uz compinit && compinit -u

# Prevents .zshrc updating by zplugin installer.
# <<zplugin>>

if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi

if has zprof; then
  zprof | less
fi
