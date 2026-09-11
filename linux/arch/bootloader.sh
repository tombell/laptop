#!/usr/bin/env bash
set -euo pipefail

source "$ROOT_DIR/linux/arch/limine-menu.sh"

check_encrypted_boot_prerequisites() {
  if [ "$(uname -m)" != x86_64 ] || [ ! -d /sys/firmware/efi ]; then
    die "This profile requires an x86_64 system booted in UEFI mode"
  fi
  if [ "$(findmnt -nro FSTYPE /)" != btrfs ] || [ "$(findmnt -nro FSROOT /)" != /@ ]; then
    die "Expected Btrfs subvolume @ mounted at /"
  fi
  if [ "$(findmnt -nro FSTYPE --mountpoint /boot)" != vfat ]; then
    die "Mount the FAT EFI system partition at /boot before running this profile"
  fi
}

encrypted_root_luks_uuid() {
  local root_source root_device parent_device luks_uuid

  root_source=$(findmnt -nro SOURCE --nofsroot /) || return
  root_device=$(readlink -f "$root_source") || return
  if [ "$(lsblk -dnro TYPE "$root_device")" != crypt ]; then
    die "Expected / to be on a directly mapped LUKS volume, without LVM"
  fi
  local parent_devices=(/sys/class/block/"${root_device##*/}"/slaves/*)
  if [ "${#parent_devices[@]}" -ne 1 ] || [ ! -e "${parent_devices[0]}" ]; then
    die "Expected exactly one backing device for the LUKS mapping"
  fi
  parent_device="/dev/${parent_devices[0]##*/}"
  luks_uuid=$(sudo cryptsetup luksUUID "$parent_device") || return
  if [[ ! "$luks_uuid" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]]; then
    die "Could not read the root device's LUKS UUID"
  fi
  printf '%s\n' "$luks_uuid"
}

write_mkinitcpio_config() {
  local config_name=$1

  log "Configuring mkinitcpio"
  sudo install -d /etc/mkinitcpio.conf.d
  sudo tee "/etc/mkinitcpio.conf.d/$config_name" >/dev/null
}

write_systemd_mkinitcpio_config() {
  local config_name=$1
  shift

  # Read machine-specific modules from stdin, then add the shared systemd hooks.
  {
    cat
    printf 'HOOKS=(base systemd'
    if (( $# )); then
      printf ' %s' "$@"
    fi
    printf ' autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)\n'
  } | write_mkinitcpio_config "$config_name"
}

install_limine_bootloader() {
  require_command limine-mkinitcpio "build kernel entries"
  require_command limine-install "install the bootloader"

  # Build successfully before replacing the working EFI loader.
  log "Building Limine kernel entries"
  sudo limine-mkinitcpio

  log "Installing Limine bootloader"
  sudo limine-install "$@"
}
