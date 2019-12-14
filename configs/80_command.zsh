# shellcheck shell=bash

# execute whenever the current working directory is changed
chpwd() {
  ll
}

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
  local f_zsh=(~/.zshrc ~/.zshenv "$DOTFILES"/zsh/*.zsh)
  for f in "${f_zsh[@]}"; do zcompile "$f"; done
}
