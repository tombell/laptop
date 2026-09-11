#!/usr/bin/env bash
set -euo pipefail

log "Configuring iwd, systemd-networkd, and systemd-resolved"

# Keep existing administrator and generated network definitions, including masks.
network_configured=false
for network_directory in /etc/systemd/network /run/systemd/network /usr/local/lib/systemd/network; do
  for network_file in "$network_directory"/*.network; do
    if [[ -e "$network_file" || -L "$network_file" ]]; then
      network_configured=true
    fi
  done
done
if [[ "$network_configured" == false ]]; then
  for network_file in "$ROOT_DIR/linux/arch/config/network/"*.network; do
    sudo install -Dm644 "$network_file" "/etc/systemd/network/${network_file##*/}"
  done
else
  log "Keeping existing networkd configuration"
fi

# enable --now starts inactive services without restarting active connections.
sudo systemctl enable --now iwd.service systemd-networkd.service systemd-resolved.service
if [[ "$(readlink -f /etc/resolv.conf || true)" != /run/systemd/resolve/stub-resolv.conf ]]; then
  if [[ -e /etc/resolv.conf || -L /etc/resolv.conf ]]; then
    if [[ ! -e /etc/resolv.conf.pre-laptop && ! -L /etc/resolv.conf.pre-laptop ]]; then
      sudo cp -a /etc/resolv.conf /etc/resolv.conf.pre-laptop
    fi
  fi
  sudo ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
fi

log "Network services enabled. New network definitions apply when links next appear or after reboot"
