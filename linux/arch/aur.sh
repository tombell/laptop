#!/usr/bin/env bash
set -euo pipefail

echo "==> Configuring makepkg…"

sudo sed -i '/^OPTIONS=(/s/\(^.*\s\)\(debug\)\(\s.*$\)/\1!debug\3/' /etc/makepkg.conf

sudo pacman -S --noconfirm --needed base-devel git

if ! command -v yay &>/dev/null; then
  install_yay() {
    local temp_dir

    command -v git >/dev/null || {
      echo "git is required to install yay" >&2
      exit 1
    }

    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' RETURN

    git clone https://aur.archlinux.org/yay.git "$temp_dir/yay"
    (cd "$temp_dir/yay" && makepkg -si --noconfirm --rmdeps)

    rm -rf "$temp_dir"
    trap - RETURN
  }

  echo "==> Installing yay AUR helper…"
  install_yay
fi
