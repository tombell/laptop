#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"

if [[ "$EUID" -eq 0 ]]; then
  echo "Run Arch system setup as your regular user with sudo access." >&2
  exit 1
fi

pacman -Q iwd zram-generator bluez power-profiles-daemon greetd >/dev/null

source "$ROOT_DIR/linux/arch/network.sh"
source "$ROOT_DIR/linux/arch/zram.sh"
source "$ROOT_DIR/linux/arch/services.sh"
source "$ROOT_DIR/linux/arch/login-manager.sh"
