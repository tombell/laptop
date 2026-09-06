#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common/bootstrap.sh"
setup_laptop_root

source "$ROOT_DIR/common/rcm.sh"

source "$ROOT_DIR/linux/debian/packages.sh"

ensure_dotfiles
# Install only base dotfiles, without profile tags or forwarded arguments.
setup_dotfiles --
