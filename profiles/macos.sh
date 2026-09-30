#!/usr/bin/env bash
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/../common/bootstrap.sh"
setup_laptop_root

profile=${1:-}

if [[ "$profile" != personal ]]; then
  die "Usage: $0 personal"
fi

log "Setting up $profile macOS laptop"

source "$ROOT_DIR/common/rcm.sh"
source "$ROOT_DIR/common/ssh.sh"

source "$ROOT_DIR/macos/homebrew.sh"

source "$ROOT_DIR/macos/shell.sh"

ensure_dotfiles
setup_dotfiles macos personal

signin_1password
setup_ssh_key "Personal" "Personal"

source "$ROOT_DIR/macos/defaults.sh"
source "$ROOT_DIR/common/mise.sh"
source "$ROOT_DIR/common/herdr.sh"

log "macOS setup complete"
