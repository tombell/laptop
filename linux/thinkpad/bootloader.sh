#!/usr/bin/env bash
set -euo pipefail

prepare_thinkpad_bootloader() {
  log "Checking ThinkPad boot prerequisites"

  if [ -f /etc/default/limine ]; then
    return
  fi
  require_command blkid "detect the encrypted root partition"

  local partuuid partuuids=()
  while IFS= read -r partuuid; do
    partuuids+=("$partuuid")
  done < <(sudo blkid -t TYPE=crypto_LUKS -s PARTUUID -o value)

  if [ "${#partuuids[@]}" -ne 1 ]; then
    die "Expected exactly one crypto_LUKS PARTUUID, found ${#partuuids[@]}"
  fi

  thinkpad_root_partuuid="${partuuids[0]}"
}

install_thinkpad_bootloader() {
  log "Configuring ThinkPad encrypted boot"

  if [ ! -f /etc/default/limine ]; then
    sudo tee /etc/default/limine <<EOF >/dev/null
KERNEL_CMDLINE[default]+="cryptdevice=PARTUUID=$thinkpad_root_partuuid:root"
KERNEL_CMDLINE[default]+="root=/dev/mapper/root rootflags=subvol=@ rw rootfstype=btrfs zswap.enabled=0"
KERNEL_CMDLINE[default]+="quiet splash loglevel=0 rd.systemd.show_status=false systemd.show_status=false udev.log_level=3 vt.global_cursor_default=0 modprobe.blacklist=sp5100_tco"

ENABLE_UKI=yes

ENABLE_LIMINE_FALLBACK=yes

FIND_BOOTLOADERS=no

BOOT_ORDER="*, *fallback, Snapshots"

MAX_SNAPSHOT_ENTRIES=5
SNAPSHOT_FORMAT_CHOICE=5
EOF
  fi

  # Add Plymouth hooks after its package is installed.
  log "Configuring Plymouth"
  if ! grep -Eq '^MODULES=.*\bamdgpu\b' /etc/mkinitcpio.conf; then
    sudo sed -Ei 's/^MODULES=\((.*)\)$/MODULES=(amdgpu \1)/' /etc/mkinitcpio.conf
  fi
  if ! grep -Eq '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf; then
    sudo sed -Ei 's/\budev\b/udev plymouth/' /etc/mkinitcpio.conf
  fi

  configure_limine_menu
  install_limine_bootloader
}
