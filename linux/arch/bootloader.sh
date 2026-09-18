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

  # Read machine-specific modules from stdin, then add the shared boot hooks.
  {
    cat
    printf 'HOOKS=(base systemd plymouth autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)\n'
  } | write_mkinitcpio_config "$config_name"
}

write_limine_kernel_cmdline() {
  local luks_uuid=$1 parameters=$2

  cat <<EOF
KERNEL_CMDLINE[default]="rd.luks.name=$luks_uuid=root root=/dev/mapper/root rootflags=subvol=@ rw rootfstype=btrfs zswap.enabled=0 quiet splash loglevel=0 systemd.show_status=false udev.log_level=3 vt.global_cursor_default=0 $parameters"
EOF
}

write_limine_defaults() {
  # Append shared defaults to the machine-specific kernel command line.
  cat
  cat "$ROOT_DIR/linux/arch/limine-defaults.conf"
}

configure_limine_config() {
  local writer=$1 luks_uuid=$2
  local config_dir

  config_dir=$(mktemp -d)
  # Finish generating the configuration before replacing the live defaults.
  if ! "$writer" "$luks_uuid" >"$config_dir/limine"; then
    rm -rf "$config_dir"
    die "Could not generate Limine configuration; boot configuration was not changed"
  fi

  sudo install -m 0644 "$config_dir/limine" /etc/default/limine

  rm -rf "$config_dir"
}

validate_installed_limine_kernel_cmdlines() {
  local luks_uuid=$1
  shift

  require_command limine-entry-tool "verify the kernel command lines"
  local kernel_file kernel
  local kernels=("$@")
  for kernel_file in /usr/lib/modules/*/pkgbase; do
    [ -f "$kernel_file" ] || continue
    kernel=$(cat "$kernel_file")
    kernels+=("$kernel" "$kernel-fallback")
  done

  validate_limine_kernel_cmdlines "$luks_uuid" root "${kernels[@]}"
}

validate_limine_kernel_cmdlines() {
  local luks_uuid=$1 mapper=$2
  shift 2

  local kernel cmdline parameter
  local expected_luks="rd.luks.name=$luks_uuid=$mapper"
  local expected_root="root=/dev/mapper/$mapper"

  for kernel in "$@"; do
    cmdline=$(limine-entry-tool --get-cmdline "$kernel") || return
    if [[ " $cmdline " != *" $expected_luks "* || " $cmdline " != *" $expected_root "* ]]; then
      die "Missing root encryption parameters for $kernel; check Limine command-line overrides"
    fi

    local parameters=()
    read -r -a parameters <<<"$cmdline"

    for parameter in "${parameters[@]}"; do
      case "$parameter" in
      cryptdevice=* | cryptkey=*)
        die "Legacy encryption parameter for $kernel; check Limine command-line overrides"
        ;;
      rd.luks.name=*)
        [ "$parameter" = "$expected_luks" ] || die "Conflicting encryption mapping for $kernel"
        ;;
      root=*)
        [ "$parameter" = "$expected_root" ] || die "Conflicting root device for $kernel"
        ;;
      esac
    done
  done
}

install_limine_bootloader() {
  require_command limine-mkinitcpio "build kernel entries"
  require_command limine-install "install the bootloader"

  log "Building Limine kernel entries"
  sudo limine-mkinitcpio

  # Enable fallback deployment only after the boot images build successfully.
  sudo sed -i 's/^ENABLE_LIMINE_FALLBACK=no$/ENABLE_LIMINE_FALLBACK=yes/' /etc/default/limine
  log "Installing Limine bootloader"
  sudo limine-install --fallback
}
