# shellcheck shell=bash

# execute whenever the current working directory is changed
chpwd() {
  ll
}

fghq() {
  local ghq_root
  ghq_root=$(ghq root)

  local repo
  repo=$(ghq list | fzf-tmux) || return 1

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
  for _ in $(seq 1 10); do sleep 0.1; time zsh -i -c exit; done
}

zshcompiles() {
  local f_zsh=(~/.zshrc ~/.zshenv "$DOTFILES"/zsh/*.zsh)
  for f in "${f_zsh[@]}"; do zcompile "$f"; done
}
