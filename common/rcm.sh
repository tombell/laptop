#!/usr/bin/env bash
set -euo pipefail

setup_dotfiles() {
  local tags=()
  local extra_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --)
      shift
      break
      ;;
    *)
      tags+=("$1")
      shift
      ;;
    esac
  done

  extra_args=("$@")

  local tag_args=()
  for tag in "${tags[@]}"; do
    tag_args+=("-t" "$tag")
  done

  require_command rcup "set up dotfiles"
  log "Applying dotfiles with rcm"

  if [ "${#extra_args[@]}" -gt 0 ]; then
    rcup -d "${HOME}/.dotfiles" \
      "${tag_args[@]}" \
      -S agents/skills -S config/rex/custom_ui \
      -x LICENSE -x README.md \
      "${extra_args[@]}"
  else
    rcup -d "${HOME}/.dotfiles" \
      "${tag_args[@]}" \
      -S agents/skills -S config/rex/custom_ui \
      -x LICENSE -x README.md
  fi

  log "Building the bat theme cache"
  if command -v bat >/dev/null; then
    bat cache --build
  else
    # Debian provides bat as batcat.
    require_command batcat "build the bat theme cache"
    batcat cache --build
  fi
}
