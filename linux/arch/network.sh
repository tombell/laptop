#!/usr/bin/env bash
set -euo pipefail

log "Configuring iwd, systemd-networkd, and systemd-resolved"

network_templates="$ROOT_DIR/linux/arch/config/network"
network_dest=/etc/systemd/network
keep_existing_network=false
for network_directory in "$network_dest" /run/systemd/network /usr/local/lib/systemd/network; do
  for network_file in "$network_directory"/*.network; do
    [[ -e "$network_file" || -L "$network_file" ]] || continue
    # A previous run may have installed only some of our templates.
    if [[ "$network_directory" == "$network_dest" && -f "$network_file" && ! -L "$network_file" ]] &&
      cmp -s "$network_file" "$network_templates/${network_file##*/}"; then
      continue
    fi
    keep_existing_network=true
    break 2
  done
done

if [[ "$keep_existing_network" == false ]]; then
  for network_file in "$network_templates"/*.network; do
    dest_file="$network_dest/${network_file##*/}"
    [[ -e "$dest_file" || -L "$dest_file" ]] || sudo install -Dm644 "$network_file" "$dest_file"
  done
else
  log "Keeping existing networkd configuration"
fi

sudo systemctl enable --now iwd.service systemd-networkd.service systemd-resolved.service

if [[ "$(readlink -f /etc/resolv.conf || true)" != /run/systemd/resolve/stub-resolv.conf ]]; then
  sudo ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
fi

log "Network services enabled. New network definitions apply when links next appear or after reboot"
