#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)/common/bootstrap.sh"
setup_laptop_root

require_regular_user "setup arch user"
systemctl --user show-environment >/dev/null || {
  die "A running systemd user session is required for user configuration"
}

log "Setting up Arch user configuration"

source "$ROOT_DIR/common/rcm.sh"
source "$ROOT_DIR/common/ssh.sh"

ensure_dotfiles
setup_dotfiles linux
source "$ROOT_DIR/linux/shared/desktop.sh"
source "$ROOT_DIR/linux/shared/audio.sh"

if [[ ! -e "$HOME/.ssh/Personal" || ! -e "$HOME/.ssh/Personal.pub" ]]; then
  signin_1password
fi
setup_ssh_key "Personal" "Personal"

source "$ROOT_DIR/linux/shared/shell.sh"
source "$ROOT_DIR/common/mise.sh"

log "Arch user setup complete"
