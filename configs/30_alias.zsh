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

__list_path() {
  echo "${path}" | tr ' ' '\n'
}
alias path=__list_path
