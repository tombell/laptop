#!/usr/bin/env bash
set -euo pipefail

prepare_thinkpad_bootloader() {
  log "Checking ThinkPad boot prerequisites"

  check_encrypted_boot_prerequisites
  encrypted_root_luks_uuid >/dev/null
}

write_thinkpad_limine_config() {
  local luks_uuid=$1

  write_limine_kernel_cmdline "$luks_uuid" "modprobe.blacklist=sp5100_tco" | write_limine_defaults
}

configure_thinkpad_bootloader() {
  local luks_uuid=$1

  log "Configuring ThinkPad encrypted boot"

  configure_limine_config write_thinkpad_limine_config "$luks_uuid"

  write_systemd_mkinitcpio_config 10-thinkpad-encryption.conf <<'EOF'
MODULES=(amdgpu)
EOF

  configure_limine_menu
}

install_thinkpad_bootloader() {
  local luks_uuid
  luks_uuid=$(encrypted_root_luks_uuid)

  configure_thinkpad_bootloader "$luks_uuid"
  validate_installed_limine_kernel_cmdlines "$luks_uuid" linux linux-fallback
  install_limine_bootloader
}
