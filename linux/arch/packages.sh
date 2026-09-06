#!/usr/bin/env bash
set -euo pipefail

LAPTOP_ROOT="${LAPTOP_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"

package_dir="$LAPTOP_ROOT/linux/arch/packages"
if [ -n "${ARCH_PACKAGE_PROFILE:-}" ]; then
  package_dir="$package_dir/$ARCH_PACKAGE_PROFILE"
fi

mapfile -t pacman_packages <"$package_dir/pacman.txt"
sudo pacman -S --noconfirm --needed "${pacman_packages[@]}"

command -v yay >/dev/null || {
  echo "yay is required to install AUR packages" >&2
  exit 1
}

mapfile -t aur_packages <"$package_dir/aur.txt"
yay -S --noconfirm --needed --removemake "${aur_packages[@]}"
