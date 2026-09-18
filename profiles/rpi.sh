#!/usr/bin/env bash
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/../common/bootstrap.sh"
setup_laptop_root

source "$ROOT_DIR/common/rcm.sh"

source "$ROOT_DIR/linux/debian/packages.sh"
source "$ROOT_DIR/linux/shared/shell.sh"

ensure_dotfiles
# Install base dotfiles without editor, agent, Pi, or SSH configuration.
setup_dotfiles -- -x agents -x config/nvim -x pi -x ssh/config
