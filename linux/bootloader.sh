#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up limine bootloader…"

if [ ! -f "/etc/default/limine" ]; then
  PARTUUID=$(blkid | grep 'TYPE="crypto_LUKS"' | sed -n 's/.*PARTUUID="\([^-"]*\(-[^"]*\)\{3\}\)".*/\1/p')

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

yay -S --noconfirm --needed --removemake zulu-21-bin
yay -S --noconfirm --needed --removemake limine-mkinitcpio-hook

if ! efibootmgr | grep -qi "Arch Linux UKI"; then
  echo "==> Setting up unified kernal image boot manager entry…"

  sudo efibootmgr --create \
    --disk "$(findmnt -n -o SOURCE /boot | sed 's/p\?[0-9]*$//')" \
    --part "$(findmnt -n -o SOURCE /boot | grep -o 'p\?[0-9]*$' | sed 's/^p//')" \
    --label "Arch Linux UKI" \
    --loader "\\EFI\\Linux\\$(cat /etc/machine-id)_linux.efi"
fi
