# shellcheck shell=bash
# shellcheck disable=SC1090

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

zplugin ice atclone"dircolors -b LS_COLORS > c.zsh" atpull'%atclone' pick"c.zsh"
zplugin light trapd00r/LS_COLORS

zplugin creinstall -q "$DOTFILES"/zsh/compdefs
zplugin creinstall -q "$DOTFILES"/zsh/compdefs_local

autoload -Uz compinit && compinit -u
