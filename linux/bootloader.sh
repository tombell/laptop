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
KERNEL_CMDLINE[default]+="quiet loglevel=0 systemd.show_status=auto udev.log_level=0 vt.global_cursor_default=0 modprobe.blacklist=sp5100_tco"

ENABLE_UKI=yes

ENABLE_LIMINE_FALLBACK=yes

FIND_BOOTLOADERS=no

BOOT_ORDER="*, *fallback, Snapshots"

MAX_SNAPSHOT_ENTRIES=5
SNAPSHOT_FORMAT_CHOICE=5
EOF
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

command -v yay >/dev/null || {
  echo "yay is required to install bootloader packages" >&2
  exit 1
}

yay -S --noconfirm --needed --removemake zulu-21-bin
yay -S --noconfirm --needed --removemake limine-mkinitcpio-hook

command -v efibootmgr >/dev/null || {
  echo "efibootmgr is required to inspect or create the boot manager entry" >&2
  exit 1
}

if ! efibootmgr | grep -qi "Arch Linux UKI"; then
  command -v findmnt >/dev/null || {
    echo "findmnt is required to inspect /boot" >&2
    exit 1
  }

  command -v lsblk >/dev/null || {
    echo "lsblk is required to inspect /boot" >&2
    exit 1
  }

  boot_source="$(findmnt -n -o SOURCE /boot)"
  boot_disk="/dev/$(lsblk -no PKNAME "$boot_source")"
  boot_part="$(lsblk -no PARTN "$boot_source")"

  if [ -z "$boot_source" ] || [ "$boot_disk" = "/dev/" ] || [ -z "$boot_part" ]; then
    echo "Could not determine /boot disk and partition" >&2
    exit 1
  fi

  echo "==> Setting up unified kernel image boot manager entry…"

  sudo efibootmgr --create \
    --disk "$boot_disk" \
    --part "$boot_part" \
    --label "Arch Linux UKI" \
    --loader "\\EFI\\Linux\\$(cat /etc/machine-id)_linux.efi"
fi
