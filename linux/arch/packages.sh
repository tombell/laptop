#!/usr/bin/env bash
set -euo pipefail

LAPTOP_ROOT="${LAPTOP_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"

mapfile -t pacman_packages <"$LAPTOP_ROOT/linux/arch/packages/pacman.txt"
sudo pacman -S --noconfirm --needed "${pacman_packages[@]}"

command -v yay >/dev/null || {
  echo "yay is required to install AUR packages" >&2
  exit 1
}

mapfile -t aur_packages <"$LAPTOP_ROOT/linux/arch/packages/aur.txt"
yay -S --noconfirm --needed --removemake "${aur_packages[@]}"
