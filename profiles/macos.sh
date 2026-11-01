#!/usr/bin/env bash
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/../common/bootstrap.sh"
setup_laptop_root

case "${1:-}" in
pyra)
  computer_name=Pyra
  role=personal
  ;;
brighid)
  computer_name=Brighid
  role=mini
  ;;
*)
  die "Usage: $0 pyra|brighid"
  ;;
esac

export HOMEBREW_LAPTOP_MACHINE=$role

log "Setting up $computer_name ($role) macOS machine"

source "$ROOT_DIR/common/rcm.sh"
source "$ROOT_DIR/common/ssh.sh"

source "$ROOT_DIR/macos/computer-name.sh"
set_computer_name "$computer_name"

source "$ROOT_DIR/macos/homebrew.sh"

source "$ROOT_DIR/macos/shell.sh"

ensure_dotfiles
setup_dotfiles macos "$role"

signin_1password
setup_ssh_key "Personal" "Personal"

source "$ROOT_DIR/macos/defaults.sh"
source "$ROOT_DIR/common/mise.sh"

log "macOS setup complete"
