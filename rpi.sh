#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common/bootstrap.sh"
setup_laptop_root

source "$ROOT_DIR/common/rcm.sh"

source "$ROOT_DIR/linux/debian/packages.sh"

ensure_dotfiles
# Install base dotfiles without Neovim configuration.
setup_dotfiles -- -x config/nvim
