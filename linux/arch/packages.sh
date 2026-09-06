#!/usr/bin/env bash
set -euo pipefail

LAPTOP_ROOT="${LAPTOP_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
package_dir="$LAPTOP_ROOT/linux/arch/packages"
package_profile="${ARCH_PACKAGE_PROFILE:-thinkpad}"

case "$package_profile" in
thinkpad | macbook) ;;
*)
  echo "Unknown Arch package profile: $package_profile" >&2
  exit 1
  ;;
esac

# Read both sets before installing anything. sort removes duplicate entries.
pacman_list=$(sort -u "$package_dir/common/pacman.txt" "$package_dir/$package_profile/pacman.txt")
aur_list=$(sort -u "$package_dir/common/aur.txt" "$package_dir/$package_profile/aur.txt")
mapfile -t pacman_packages <<<"$pacman_list"
mapfile -t aur_packages <<<"$aur_list"

command -v yay >/dev/null || {
  echo "yay is required to install AUR packages" >&2
  exit 1
}

sudo pacman -S --noconfirm --needed "${pacman_packages[@]}"
yay -S --noconfirm --needed --removemake "${aur_packages[@]}"
