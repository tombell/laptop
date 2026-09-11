#!/usr/bin/env bash
set -euo pipefail

setup_laptop_root() {
  ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
  export ROOT_DIR
  export LAPTOP_ROOT="$ROOT_DIR"
}

log() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_regular_user() {
  if [[ "$EUID" -eq 0 ]]; then
    die "Run $1 as your regular user with sudo access"
  fi
}

require_command() {
  local command_name=$1
  local reason=${2:-run this script}

  command -v "$command_name" >/dev/null || die "$command_name is required to ${reason}"
}

ensure_dotfiles() {
  if [ ! -d "$HOME/.dotfiles" ]; then
    require_command git "clone dotfiles"
    log "Cloning dotfiles"
    git clone https://github.com/tombell/dotfiles.git "$HOME/.dotfiles"
  fi
}

signin_1password() {
  require_command op "sign in to 1Password"
  log "Signing in to 1Password"
  eval "$(op signin)"
}
