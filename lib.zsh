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
  local -r CMD=${1}

  (( ${+commands[${CMD}]} ))
}

alias has='__exists_command'

__is_gnu_coreutils() {
  local -r CMD=${1}

  ${CMD} --version | grep -q GNU
}

alias gnu='__is_gnu_coreutils'
