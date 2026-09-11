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

configure_thinkpad_bootloader() {
  log "Configuring ThinkPad encrypted boot"

  write_mkinitcpio_config 10-thinkpad-encryption.conf <<'EOF'
# Keep existing modules and hooks, including changes made by earlier setup runs.
if [[ ! " ${MODULES[*]} " == *" amdgpu "* ]]; then
  MODULES=(amdgpu "${MODULES[@]}")
fi

if [[ ! " ${HOOKS[*]} " == *" plymouth "* ]]; then
  for laptop_hook_index in "${!HOOKS[@]}"; do
    if [[ "${HOOKS[laptop_hook_index]}" == udev ]]; then
      HOOKS=("${HOOKS[@]:0:laptop_hook_index+1}" plymouth "${HOOKS[@]:laptop_hook_index+1}")
      break
    fi
  done
  unset laptop_hook_index
fi
EOF

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

  configure_limine_menu
}

install_thinkpad_bootloader() {
  # Add Plymouth hooks after its package is installed.
  configure_thinkpad_bootloader
  install_limine_bootloader
}
