#!/usr/bin/env bash
set -euo pipefail

prepare_macbook_bootloader() {
  log "Checking T2 MacBook boot prerequisites"

  if [ "$(uname -m)" != x86_64 ] || [ ! -d /sys/firmware/efi ]; then
    die "This profile requires an Intel Mac running Arch in UEFI mode"
  fi
  pacman -Q linux-t2 >/dev/null
  if [ "$(findmnt -nro FSTYPE /)" != btrfs ] || [ "$(findmnt -nro FSROOT /)" != /@ ]; then
    die "Expected Btrfs subvolume @ mounted at /"
  fi
  if [ "$(findmnt -nro FSTYPE --mountpoint /boot)" != vfat ]; then
    die "Mount the FAT EFI system partition at /boot before running this profile"
  fi

  local root_device parent_device luks_uuid kernel_dir kernel_version
  root_device=$(readlink -f "$(findmnt -nro SOURCE --nofsroot /)")
  if [ "$(lsblk -dnro TYPE "$root_device")" != crypt ]; then
    die "Expected / to be on a directly mapped LUKS volume, without LVM"
  fi
  local parent_devices=(/sys/class/block/"${root_device##*/}"/slaves/*)
  if [ "${#parent_devices[@]}" -ne 1 ] || [ ! -e "${parent_devices[0]}" ]; then
    die "Expected exactly one backing device for the LUKS mapping"
  fi
  parent_device="/dev/${parent_devices[0]##*/}"
  luks_uuid=$(sudo cryptsetup luksUUID "$parent_device")

  kernel_version=""
  for kernel_dir in /usr/lib/modules/*; do
    if [ -f "$kernel_dir/pkgbase" ] && [ "$(cat "$kernel_dir/pkgbase")" = linux-t2 ]; then
      kernel_version=${kernel_dir##*/}
      modinfo -k "$kernel_version" t2bce_vhci >/dev/null
    fi
  done
  if [ -z "$kernel_version" ]; then
    die "Install a linux-t2 kernel with t2bce before running this profile"
  fi

  # Configure T2 boot before package hooks rebuild the kernel images.
  configure_macbook_bootloader "$luks_uuid"
}

configure_macbook_bootloader() {
  local luks_uuid=$1

  log "Configuring T2 encrypted boot"

  write_mkinitcpio_config 10-t2-encryption.conf <<'EOF'
MODULES=(t2bce_dma t2bce_core t2bce_vhci usbhid hid_apple)
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
EOF
  sudo install -d /etc/modules-load.d
  echo t2bce_vhci | sudo tee /etc/modules-load.d/t2.conf >/dev/null

  if [ -f /etc/default/limine ] && [ ! -f /etc/default/limine.pre-macbook ]; then
    sudo cp /etc/default/limine /etc/default/limine.pre-macbook
  fi
  sudo tee /etc/default/limine <<EOF >/dev/null
ESP_PATH=/boot
KERNEL_CMDLINE[default]="rd.luks.name=$luks_uuid=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw rootfstype=btrfs intel_iommu=on iommu=pt pm_async=off"
ENABLE_UKI=yes
ENABLE_LIMINE_FALLBACK=no
FIND_BOOTLOADERS=no
EOF

  configure_limine_menu
}

install_macbook_bootloader() {
  install_limine_bootloader --fallback
  sudo sed -i 's/^ENABLE_LIMINE_FALLBACK=no$/ENABLE_LIMINE_FALLBACK=yes/' /etc/default/limine
}
