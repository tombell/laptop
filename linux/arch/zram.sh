#!/usr/bin/env bash
set -euo pipefail

log "Configuring zram"

zram_configured=false
for zram_directory in /etc/systemd /run/systemd /usr/local/lib/systemd /usr/lib/systemd; do
  for zram_config in "$zram_directory/zram-generator.conf" "$zram_directory"/zram-generator.conf.d/*.conf; do
    if [[ -e "$zram_config" || -L "$zram_config" ]]; then
      zram_configured=true
    fi
  done
done
if [[ "$zram_configured" == false ]]; then
  sudo install -Dm644 "$ROOT_DIR/linux/arch/config/zram-generator.conf" /etc/systemd/zram-generator.conf
else
  log "Keeping existing zram configuration"
fi

zram_dropin=/etc/systemd/system/systemd-zram-setup@zram0.service.d/disable-zswap.conf
if [[ ! -e "$zram_dropin" && ! -L "$zram_dropin" ]]; then
  sudo install -Dm644 "$ROOT_DIR/linux/arch/config/disable-zswap.conf" "$zram_dropin"
fi
sudo systemctl daemon-reload

if [[ "$(systemctl show --property=LoadState --value dev-zram0.swap)" == loaded ]]; then
  # Do not restart or resize an active swap device. Apply the zswap setting now
  # as well, since an already-running setup service will not rerun ExecStartPre.
  if systemctl is-active --quiet dev-zram0.swap; then
    sudo sh -c 'if [ -e /sys/module/zswap/parameters/enabled ]; then echo N > /sys/module/zswap/parameters/enabled; fi'
  fi
  sudo systemctl start dev-zram0.swap
else
  log "Keeping existing swap configuration without zram0"
fi
