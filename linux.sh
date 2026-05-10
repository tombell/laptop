#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export LAPTOP_ROOT="$ROOT_DIR"

source "$ROOT_DIR/common/rcm.sh"
source "$ROOT_DIR/common/ssh.sh"

source "$ROOT_DIR/linux/pacman.sh"
source "$ROOT_DIR/linux/aur.sh"
source "$ROOT_DIR/linux/packages.sh"

if [ ! -d "$HOME/.dotfiles" ]; then
  command -v git >/dev/null || {
    echo "git is required to clone dotfiles" >&2
    exit 1
  }

  git clone https://github.com/tombell/dotfiles.git "$HOME/.dotfiles"
fi

setup_dotfiles linux

# TODO: log into 1password here so we can get SSH keys
setup_ssh_key "Personal" "Personal"

source "$ROOT_DIR/linux/bootloader.sh"
source "$ROOT_DIR/linux/snapshots.sh"
source "$ROOT_DIR/linux/fonts.sh"
source "$ROOT_DIR/linux/login-manager.sh"
source "$ROOT_DIR/linux/shell.sh"
source "$ROOT_DIR/linux/gui.sh"
source "$ROOT_DIR/common/mise.sh"
