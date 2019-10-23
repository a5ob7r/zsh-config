if grep --version | grep -q GNU; then
  alias grep='grep --color=auto'
  alias gr="grep -F -irn --exclude-dir='.git'"
fi

# define alias of colorful and detail ls
if (( $+commands[exa] )); then
  alias ll='exa -1'
  alias la='exa -lag --icons'
elif ls --version | grep -q GNU; then
  # when GNU LS(= coreutils) is installed
  alias ls='ls --color=auto'
  alias ll='ls -1'
  alias la='ls -lAh'
else
  # BSD LS
  alias ll='ls -1G'
  alias la="ls -hlTAFG"
fi

alias mv='mv -in'

if (( $+commands[docker] )); then
  alias dk='docker'
fi

if (( $+commands[docker-compose] )); then
  alias dkcp='docker-compose'
fi

if (( $+commands[tmux] )); then
  alias t='tmux'
fi

if (( $+commands[hub] )); then
  alias g='hub'
elif (( $+commands[git] )); then
  alias g='git'
fi

if (( $+commands[volt] )); then
  alias v='volt'
  alias vb='volt build'
fi

if (( $+commands[pipenv])); then
  alias p='pipenv'
fi

alias cdh='cd ~'
alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'
alias shinit='exec $SHELL -l'
