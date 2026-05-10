#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up btrfs snapshots…"

command -v yay >/dev/null || {
  echo "yay is required to install snapshot packages" >&2
  exit 1
}

yay -S --noconfirm --needed --removemake limine-snapper-sync snap-pac

command -v snapper >/dev/null || {
  echo "snapper is required to configure btrfs snapshots" >&2
  exit 1
}

if ! sudo snapper list-configs 2>/dev/null | grep -q "root"; then
  sudo snapper -c root create-config /
fi

if ! sudo snapper list-configs 2>/dev/null | grep -q "home"; then
  sudo snapper -c home create-config /home
fi

sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/{root,home}

sudo systemctl enable --now limine-snapper-sync.service
