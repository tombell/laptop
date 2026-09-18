#!/usr/bin/env bash
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/../../common/bootstrap.sh"
setup_laptop_root

system_machine=${1:-}
case "$system_machine" in
"" | thinkpad | macbook) ;;
*) die "Usage: $0 [thinkpad|macbook]" ;;
esac

require_regular_user "Arch system setup"

pacman -Q iwd zram-generator bluez power-profiles-daemon greetd >/dev/null

source "$ROOT_DIR/linux/arch/network.sh"
source "$ROOT_DIR/linux/arch/zram.sh"
source "$ROOT_DIR/linux/arch/services.sh"

if [[ -n "$system_machine" && -f "$ROOT_DIR/linux/$system_machine/services.sh" ]]; then
  # shellcheck source=/dev/null
  source "$ROOT_DIR/linux/$system_machine/services.sh"
fi

source "$ROOT_DIR/linux/arch/login-manager.sh"
