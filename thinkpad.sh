#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common/bootstrap.sh"
setup_laptop_root

source "$ROOT_DIR/common/rcm.sh"
source "$ROOT_DIR/common/ssh.sh"

source "$ROOT_DIR/linux/arch/pacman.sh"
source "$ROOT_DIR/linux/arch/aur.sh"
source "$ROOT_DIR/linux/arch/packages.sh"
source "$ROOT_DIR/linux/shared/keyring.sh"

ensure_dotfiles
setup_dotfiles linux

signin_1password
setup_ssh_key "Personal" "Personal"

source "$ROOT_DIR/linux/thinkpad/bootloader.sh"
source "$ROOT_DIR/linux/thinkpad/snapshots.sh"
source "$ROOT_DIR/linux/shared/fonts.sh"
source "$ROOT_DIR/linux/thinkpad/login-manager.sh"
source "$ROOT_DIR/linux/shared/shell.sh"
source "$ROOT_DIR/linux/shared/gui.sh"
source "$ROOT_DIR/common/mise.sh"
