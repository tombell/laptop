#!/usr/bin/env bash
set -euo pipefail

prepare_thinkpad_bootloader() {
  log "Checking ThinkPad boot prerequisites"

  check_encrypted_boot_prerequisites
  thinkpad_root_luks_uuid=$(encrypted_root_luks_uuid)
}

write_thinkpad_limine_config() {
  local luks_uuid=$1
  local existing_config=$2

  if [ -f "$existing_config" ]; then
    awk -v luks_uuid="$luks_uuid" -f "$ROOT_DIR/linux/thinkpad/limine-systemd.awk" "$existing_config"
  else
    cat <<EOF
KERNEL_CMDLINE[default]+="rd.luks.name=$luks_uuid=root"
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
}

validate_thinkpad_kernel_cmdlines() {
  local luks_uuid=$1
  shift
  local kernel cmdline

  for kernel in "$@"; do
    cmdline=$(limine-entry-tool --get-cmdline "$kernel") || return
    if [[ " $cmdline " != *" rd.luks.name=$luks_uuid=root "* ||
      " $cmdline " == *" cryptdevice="* || " $cmdline " == *" cryptkey="* ]]; then
      die "Unexpected encryption parameters for $kernel; check Limine command-line overrides"
    fi
  done
}

configure_thinkpad_bootloader() {
  log "Configuring ThinkPad encrypted boot"

  require_command limine-entry-tool "verify the migrated kernel command lines"
  local config_dir kernel_file kernel
  local kernels=(linux linux-fallback)
  config_dir=$(mktemp -d)
  # Validate the migration before changing either live configuration file.
  if ! write_thinkpad_limine_config "$thinkpad_root_luks_uuid" /etc/default/limine > "$config_dir/limine"; then
    rm -rf "$config_dir"
    die "Could not migrate ThinkPad Limine configuration; boot configuration was not changed"
  fi

  if [ -f /etc/default/limine ]; then
    sudo cp /etc/default/limine "$config_dir/previous"
    if [ ! -f /etc/default/limine.pre-systemd ]; then
      sudo cp /etc/default/limine /etc/default/limine.pre-systemd
    fi
  fi
  if [ -f /etc/mkinitcpio.conf.d/10-thinkpad-encryption.conf ] &&
    [ ! -f /etc/mkinitcpio.conf.d/10-thinkpad-encryption.conf.pre-systemd ]; then
    sudo cp /etc/mkinitcpio.conf.d/10-thinkpad-encryption.conf /etc/mkinitcpio.conf.d/10-thinkpad-encryption.conf.pre-systemd
  fi
  sudo install -m 0644 "$config_dir/limine" /etc/default/limine
  for kernel_file in /usr/lib/modules/*/pkgbase; do
    [ -f "$kernel_file" ] || continue
    kernel=$(cat "$kernel_file")
    kernels+=("$kernel" "$kernel-fallback")
  done
  # Check effective values too: per-kernel settings in other files can override defaults.
  if ! (validate_thinkpad_kernel_cmdlines "$thinkpad_root_luks_uuid" "${kernels[@]}"); then
    if [ -f "$config_dir/previous" ]; then
      sudo cp "$config_dir/previous" /etc/default/limine
    else
      sudo rm /etc/default/limine
    fi
    rm -rf "$config_dir"
    die "Restored the previous Limine configuration; mkinitcpio hooks were not changed"
  fi
  rm -rf "$config_dir"

  write_systemd_mkinitcpio_config 10-thinkpad-encryption.conf plymouth <<'EOF'
# Keep existing modules, including changes made by earlier setup runs.
if [[ ! " ${MODULES[*]} " == *" amdgpu "* ]]; then
  MODULES=(amdgpu "${MODULES[@]}")
fi
EOF

  configure_limine_menu
}

install_thinkpad_bootloader() {
  # Migrate the command line and hooks together, after Plymouth is installed.
  configure_thinkpad_bootloader
  install_limine_bootloader
}
