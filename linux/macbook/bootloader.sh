#!/usr/bin/env bash
set -euo pipefail

prepare_macbook_bootloader() {
  if [ "$EUID" -eq 0 ]; then
    echo "Run macbook.sh as your regular user with sudo access." >&2
    exit 1
  fi

  if [ "$(uname -m)" != x86_64 ] || [ ! -d /sys/firmware/efi ]; then
    echo "This profile requires an Intel Mac running Arch in UEFI mode." >&2
    exit 1
  fi
  pacman -Q linux-t2 >/dev/null
  if [ "$(findmnt -nro FSTYPE /)" != btrfs ] || [ "$(findmnt -nro FSROOT /)" != /@ ]; then
    echo "Expected Btrfs subvolume @ mounted at /." >&2
    exit 1
  fi
  if [ "$(findmnt -nro FSTYPE --mountpoint /boot)" != vfat ]; then
    echo "Mount the FAT EFI system partition at /boot before running this profile." >&2
    exit 1
  fi

  local root_device parent_device luks_uuid kernel_dir kernel_version
  root_device=$(readlink -f "/dev/block/$(findmnt -nro MAJ:MIN /)")
  if [ "$(lsblk -dnro TYPE "$root_device")" != crypt ]; then
    echo "Expected / to be on a directly mapped LUKS volume, without LVM." >&2
    exit 1
  fi
  parent_device="/dev/$(lsblk -dnro PKNAME "$root_device")"
  luks_uuid=$(sudo cryptsetup luksUUID "$parent_device")

  kernel_version=""
  for kernel_dir in /usr/lib/modules/*; do
    if [ -f "$kernel_dir/pkgbase" ] && [ "$(cat "$kernel_dir/pkgbase")" = linux-t2 ]; then
      kernel_version=${kernel_dir##*/}
      modinfo -k "$kernel_version" t2bce_vhci >/dev/null
    fi
  done
  if [ -z "$kernel_version" ]; then
    echo "Install a linux-t2 kernel with t2bce before running this profile." >&2
    exit 1
  fi

  echo "==> Preparing T2 encrypted boot and preserving GRUB…"
  sudo install -d /etc/mkinitcpio.conf.d /etc/modules-load.d /boot/EFI/GRUB
  if [ -f /boot/grub/grub.cfg ] && [ -f /boot/EFI/BOOT/BOOTX64.EFI ] && [ ! -f /boot/EFI/GRUB/BOOTX64.EFI ]; then
    sudo cp /boot/EFI/BOOT/BOOTX64.EFI /boot/EFI/GRUB/BOOTX64.EFI
  fi
  if [ -f /etc/default/limine ] && [ ! -f /etc/default/limine.pre-macbook ]; then
    sudo cp /etc/default/limine /etc/default/limine.pre-macbook
  fi

  sudo tee /etc/mkinitcpio.conf.d/10-t2-encryption.conf <<'EOF' >/dev/null
MODULES=(t2bce_dma t2bce_core t2bce_vhci usbhid hid_apple)
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
EOF
  echo t2bce_vhci | sudo tee /etc/modules-load.d/t2.conf >/dev/null
  sudo tee /etc/default/limine <<EOF >/dev/null
ESP_PATH=/boot
KERNEL_CMDLINE[default]="rd.luks.name=$luks_uuid=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw rootfstype=btrfs intel_iommu=on iommu=pt pm_async=off"
ENABLE_UKI=yes
ENABLE_LIMINE_FALLBACK=no
FIND_BOOTLOADERS=no
EOF
}

install_macbook_bootloader() {
  echo "==> Building T2 Limine entries…"
  # Build successfully before replacing the working EFI fallback loader.
  sudo limine-mkinitcpio
  if [ -f /boot/EFI/GRUB/BOOTX64.EFI ]; then
    sudo limine-entry-tool --add-efi "GRUB recovery" /boot/EFI/GRUB/BOOTX64.EFI --overwrite
  fi
  sudo limine-install --fallback
  sudo sed -i 's/^ENABLE_LIMINE_FALLBACK=no$/ENABLE_LIMINE_FALLBACK=yes/' /etc/default/limine
  echo "==> Limine installed. Keep GRUB until a successful reboot has been verified."
}
