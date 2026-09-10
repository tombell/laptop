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

# Manifests accept one package per line, optional # reasons, and blank lines.
read_package_list() {
  sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$@" | sort -u
}

# Read all sets before installing anything, deduplicating the package names.
pacman_list=$(read_package_list "$package_dir/common/pacman.txt" "$package_dir/desktop/pacman.txt" "$package_dir/$package_profile/pacman.txt")
aur_list=$(read_package_list "$package_dir/common/aur.txt" "$package_dir/desktop/aur.txt" "$package_dir/$package_profile/aur.txt")
pacman_packages=()
aur_packages=()
if [[ -n "$pacman_list" ]]; then
  mapfile -t pacman_packages <<<"$pacman_list"
fi
if [[ -n "$aur_list" ]]; then
  mapfile -t aur_packages <<<"$aur_list"
  command -v yay >/dev/null || {
    echo "yay is required to install AUR packages" >&2
    exit 1
  }
fi

# Keep replacement prompts available when the requested packages conflict with installed ones.
if (( ${#pacman_packages[@]} )); then
  sudo pacman -S --needed "${pacman_packages[@]}"
fi
if (( ${#aur_packages[@]} )); then
  yay -S --needed --removemake "${aur_packages[@]}"
fi
