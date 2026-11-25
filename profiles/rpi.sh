#!/usr/bin/env bash
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/../common/bootstrap.sh"
setup_laptop_root

source "$ROOT_DIR/common/rcm.sh"

source "$ROOT_DIR/linux/debian/packages.sh"
source "$ROOT_DIR/linux/shared/shell.sh"

ensure_dotfiles
# Omit the ai tag, and skip the Claude skills hook and the t3, editor, and SSH configs.
setup_dotfiles -- -K \
  -x t3 \
  -x config/nvim -x ssh/config
