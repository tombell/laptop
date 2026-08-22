#!/usr/bin/env bash
set -euo pipefail

sudo pacman -S --noconfirm --needed base-devel git

if ! command -v yay &>/dev/null; then
  install_yay() {
    local temp_dir

    require_command git "clone and build yay"

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
