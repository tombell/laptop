#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common/bootstrap.sh"
setup_laptop_root

source "$ROOT_DIR/common/rcm.sh"
source "$ROOT_DIR/common/ssh.sh"

source "$ROOT_DIR/linux/pacman.sh"
source "$ROOT_DIR/linux/aur.sh"
source "$ROOT_DIR/linux/packages.sh"

ensure_dotfiles
setup_dotfiles linux

signin_1password
setup_ssh_key "Personal" "Personal"

source "$ROOT_DIR/linux/bootloader.sh"
source "$ROOT_DIR/linux/snapshots.sh"
source "$ROOT_DIR/linux/fonts.sh"
source "$ROOT_DIR/linux/login-manager.sh"
source "$ROOT_DIR/linux/shell.sh"
source "$ROOT_DIR/linux/gui.sh"
source "$ROOT_DIR/common/mise.sh"
