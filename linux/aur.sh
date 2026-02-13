#!/usr/bin/env bash
set -euo pipefail

echo "==> Configuring makepkg…"

sudo sed -i '/^OPTIONS=(/s/\(^.*\s\)\(debug\)\(\s.*$\)/\1!debug\3/' /etc/makepkg.conf

sudo pacman -S --noconfirm --needed base-devel git

if ! command -v yay &>/dev/null; then
  echo "==> Installing yay AUR helper…"
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm --rmdeps
  cd ..
  rm -fr yay
fi
