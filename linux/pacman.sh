#!/usr/bin/env bash
set -euo pipefail

echo "==> Configuring pacman and updating system…"

sudo sed -i 's/^#Color/Color/' /etc/pacman.conf

sudo pacman -Syu --noconfirm --needed
