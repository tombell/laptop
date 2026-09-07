#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common/bootstrap.sh"
setup_laptop_root

if [[ "$EUID" -eq 0 ]]; then
  echo "Run arch-user.sh as your regular user." >&2
  exit 1
fi
systemctl --user show-environment >/dev/null || {
  echo "A running systemd user session is required for user configuration." >&2
  exit 1
}

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
