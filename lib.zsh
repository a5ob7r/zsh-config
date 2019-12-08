__exists_command() {
  local -r CMD=${1}

  (( ${+commands[${CMD}]} ))
}

alias has='__exists_command'

__is_gnu_coreutils() {
  local -r CMD=${1}

  ${CMD} --version 2>&1 | grep -q GNU
}

alias gnu='__is_gnu_coreutils'
