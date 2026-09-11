#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)/common/bootstrap.sh"
setup_laptop_root

machine=${1:-}
case "$machine" in
thinkpad) machine_name=ThinkPad ;;
macbook) machine_name="T2 MacBook" ;;
*) die "Usage: $0 thinkpad|macbook" ;;
esac

require_regular_user "setup arch os $machine"
log "Setting up Arch Linux on $machine_name"

source "$ROOT_DIR/linux/arch/bootloader.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/linux/$machine/bootloader.sh"
# T2 boot configuration must be in place before package hooks rebuild images.
"prepare_${machine}_bootloader"

source "$ROOT_DIR/linux/arch/pacman.sh"
source "$ROOT_DIR/linux/arch/aur.sh"
ARCH_PACKAGE_PROFILE="$machine" source "$ROOT_DIR/linux/arch/packages.sh"

"install_${machine}_bootloader"
source "$ROOT_DIR/linux/arch/snapshots.sh"
source "$ROOT_DIR/linux/arch/system.sh"

if [[ -f "$ROOT_DIR/linux/$machine/services.sh" ]]; then
  # shellcheck source=/dev/null
  source "$ROOT_DIR/linux/$machine/services.sh"
fi

log "Arch OS setup complete"
log "Run ./setup arch user before rebooting"
