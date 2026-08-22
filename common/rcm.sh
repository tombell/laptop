#!/usr/bin/env bash
set -euo pipefail

setup_dotfiles() {
  local rcup_args=()
  local tag

  for tag in "$@"; do
    rcup_args+=("-t" "$tag")
  done

  echo "==> Setting up dotfiles with rcm…"

  require_command rcup "set up dotfiles"

  rcup -d "${HOME}/.dotfiles" \
    ${rcup_args[@]+"${rcup_args[@]}"} \
    -S agents/skills \
    -x LICENSE -x README.md -x scripts
}
