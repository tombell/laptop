#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up macOS laptop…"

source "$(dirname "$0")/common/rcm.sh"
source "$(dirname "$0")/common/ssh.sh"

source "$(dirname "$0")/macos/homebrew.sh"

if [ ! -d "$HOME/.dotfiles" ]; then
  git clone https://github.com/tombell/dotfiles.git "$HOME/.dotfiles"
fi

setup_dotfiles macos

eval "$(op signin)"
setup_ssh_key "Personal" "Personal"

source "$(dirname "$0")/macos/defaults.sh"
source "$(dirname "$0")/common/mise.sh"
