#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up Limine bootloader..."

if [ ! -f "/etc/default/limine" ]; then
  command -v blkid >/dev/null || {
    echo "blkid is required to detect the encrypted root partition" >&2
    exit 1
  }

  partuuids=()
  while IFS= read -r partuuid; do
    partuuids+=("$partuuid")
  done < <(sudo blkid -t TYPE=crypto_LUKS -s PARTUUID -o value)

  if [ "${#partuuids[@]}" -ne 1 ]; then
    echo "Expected exactly one crypto_LUKS PARTUUID, found ${#partuuids[@]}" >&2
    exit 1
  fi

  PARTUUID="${partuuids[0]}"

  sudo tee /etc/default/limine <<EOF >/dev/null
KERNEL_CMDLINE[default]+="cryptdevice=PARTUUID=$PARTUUID:root"
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

echo "==> Configuring Plymouth..."
if ! grep -Eq '^MODULES=.*\bamdgpu\b' /etc/mkinitcpio.conf; then
  sudo sed -Ei 's/^MODULES=\((.*)\)$/MODULES=(amdgpu \1)/' /etc/mkinitcpio.conf
fi
if ! grep -Eq '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf; then
  sudo sed -Ei 's/\budev\b/udev plymouth/' /etc/mkinitcpio.conf
fi

source "$ROOT_DIR/linux/arch/limine-menu.sh"
configure_limine_menu

command -v limine-install >/dev/null || {
  echo "limine-install is required to install the bootloader" >&2
  exit 1
}

command -v limine-mkinitcpio >/dev/null || {
  echo "limine-mkinitcpio is required to build kernel entries" >&2
  exit 1
}

echo "==> Building Limine kernel entries..."
sudo limine-mkinitcpio

echo "==> Installing Limine and registering its UEFI entry..."
sudo limine-install
