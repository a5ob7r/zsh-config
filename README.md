# My Zsh Configures

## Setup

```sh
$ cd path/to/zsh-config
$ make link
```

## Install local zsh completions

```sh
# cd to your local completions directory
$ cd ~/.local/share/zsh/completions
$ zinit creinstall "${PWD}/completions"
```

## Local rcs

These configs can load user local zsh configs.

```sh
$ : > ~/.zprofile.local
$ : > ~/.zshrc.local
```
