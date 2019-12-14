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

if [[ -n "${TMUX}" ]] && has anyenv; then
  source ~/.anyenv/completions/anyenv.zsh
  for env in ~/.anyenv/envs/*; do
    source "${env}"/completions/*.zsh
  done
fi
