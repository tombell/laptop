#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up limine bootloader…"

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

echo "==> Configuring Plymouth…"
if ! grep -Eq '^MODULES=.*\bamdgpu\b' /etc/mkinitcpio.conf; then
  sudo sed -Ei 's/^MODULES=\((.*)\)$/MODULES=(amdgpu \1)/' /etc/mkinitcpio.conf
fi
if ! grep -Eq '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf; then
  sudo sed -Ei 's/\budev\b/udev plymouth/' /etc/mkinitcpio.conf
fi

if [ ! -f "/boot/limine.conf" ]; then
  sudo tee /boot/limine.conf <<EOF >/dev/null
default_entry: 2
interface_branding: Arch Linux Bootloader
interface_branding_color: 2
hash_mismatch_panic: no

backdrop: 1a1b26

term_palette: 15161e;f7768e;9ece6a;e0af68;7aa2f7;bb9af7;7dcfff;a9b1d6
term_palette_bright: 414868;f7768e;9ece6a;e0af68;7aa2f7;bb9af7;7dcfff;c0caf5

term_foreground: c0caf5
term_background: 1a1b26
term_foreground_bright: c0caf5
term_background_bright: 24283b

EOF
fi

command -v limine-install >/dev/null || {
  echo "limine-install is required to install the bootloader" >&2
  exit 1
}

command -v limine-mkinitcpio >/dev/null || {
  echo "limine-mkinitcpio is required to build kernel entries" >&2
  exit 1
}

echo "==> Installing Limine and registering its UEFI entry…"
sudo limine-install

echo "==> Building Limine kernel entries…"
sudo limine-mkinitcpio
