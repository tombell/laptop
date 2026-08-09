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

  echo "==> Setting up dotfiles with rcm…"

  command -v rcup >/dev/null || {
    echo "rcup is required to set up dotfiles" >&2
    exit 1
  }

  if [ "${#extra_args[@]}" -gt 0 ]; then
    rcup -d "${HOME}/.dotfiles" \
      "${tag_args[@]}" \
      -S agents/skills \
      -x LICENSE -x README.md -x scripts \
      "${extra_args[@]}"
  else
    rcup -d "${HOME}/.dotfiles" \
      "${tag_args[@]}" \
      -S agents/skills \
      -x LICENSE -x README.md -x scripts
  fi
}
