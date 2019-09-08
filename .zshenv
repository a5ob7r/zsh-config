# {{{ dotfiles
# detect and define dotfiles directory path
DOTFILES=$(dirname "$(readlink ~/.zshenv)")
export DOTFILES
# }}}

# {{{ basic
export LANG=en_US.UTF-8
export LC_TIME="C"

export EDITOR=vim
export VISUAL=vim
export PAGER=less

# prevent adding duplication path
typeset -U path PATH

export path=( \
  ~/bin(N-/) \
  ~/.local/bin(N-/) \
  "${path[@]}" \
  )
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
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
export FZF_TMUX=1
# }}}

# {{{ anyenv
init_anyenv() {
  export ANYENV_ROOT=~/.anyenv

  if ! [[ -d ${ANYENV_ROOT} ]] ; then
    return 0
  fi

  if (( $+commands[anyenv] )); then
    return 0
  fi

  export PATH="${ANYENV_ROOT}/bin:${PATH}"
  eval "$(anyenv init - --no-rehash)"
}

init_anyenv
unset -f init_anyenv
# }}}

# {{{ other
export GOPATH=~/go
export path=( \
  "${GOPATH}"/bin(N-/) \
  "${path[@]}" \
  )
export PIPENV_VENV_IN_PROJECT=1
export SPACESHIP_CHAR_SYMBOL='❯'
export SPACESHIP_CHAR_SUFFIX=' '
# }}}

# {{{ local zshenv
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
# }}}
