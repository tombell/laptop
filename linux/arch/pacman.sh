#!/usr/bin/env bash
set -euo pipefail

log "Configuring pacman"

sudo sed -i 's/^#Color/Color/' /etc/pacman.conf

log "Updating system packages"
sudo pacman -Syu --noconfirm --needed
