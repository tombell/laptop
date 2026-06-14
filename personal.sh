#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up macOS laptop…"

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common/bootstrap.sh"
setup_laptop_root

source "$ROOT_DIR/common/rcm.sh"
source "$ROOT_DIR/common/ssh.sh"

source "$ROOT_DIR/macos/homebrew.sh"

ensure_dotfiles
setup_dotfiles macos personal

signin_1password
setup_ssh_key "Personal" "Personal"

source "$ROOT_DIR/macos/defaults.sh"
source "$ROOT_DIR/common/mise.sh"
