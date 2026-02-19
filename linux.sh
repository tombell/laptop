#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common/rcm.sh"
source "$(dirname "$0")/common/ssh.sh"

source "$(dirname "$0")/linux/pacman.sh"
source "$(dirname "$0")/linux/aur.sh"
source "$(dirname "$0")/linux/packages.sh"

if [ ! -d "$HOME/.dotfiles" ]; then
  git clone https://github.com/tombell/dotfiles.git "$HOME/.dotfiles"
fi

setup_dotfiles linux

# TODO: log into 1password here so we can get SSH keys
setup_ssh_key "Personal" "Personal"

source "$(dirname "$0")/linux/bootloader.sh"
source "$(dirname "$0")/linux/snapshots.sh"
source "$(dirname "$0")/linux/fonts.sh"
source "$(dirname "$0")/linux/login-manager.sh"
source "$(dirname "$0")/linux/shell.sh"
source "$(dirname "$0")/linux/gui.sh"
source "$(dirname "$0")/common/mise.sh"
