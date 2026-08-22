#!/usr/bin/env bash
set -euo pipefail

mapfile -t pacman_packages <"$ROOT_DIR/linux/packages/pacman.txt"
sudo pacman -S --noconfirm --needed "${pacman_packages[@]}"

mapfile -t aur_packages <"$ROOT_DIR/linux/packages/aur.txt"
install_aur_package "${aur_packages[@]}"
