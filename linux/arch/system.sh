#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)/common/bootstrap.sh"
setup_laptop_root

require_regular_user "Arch system setup"

pacman -Q iwd zram-generator bluez power-profiles-daemon greetd >/dev/null

source "$ROOT_DIR/linux/arch/network.sh"
source "$ROOT_DIR/linux/arch/zram.sh"
source "$ROOT_DIR/linux/arch/services.sh"
source "$ROOT_DIR/linux/arch/login-manager.sh"
