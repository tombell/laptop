#!/usr/bin/env bash
set -euo pipefail

prepare_macbook_bootloader() {
  log "Checking T2 MacBook boot prerequisites"

  check_encrypted_boot_prerequisites
  encrypted_root_luks_uuid >/dev/null
}

write_macbook_limine_config() {
  local luks_uuid=$1

  write_limine_kernel_cmdline "$luks_uuid" "intel_iommu=on iommu=pt pm_async=off" | write_limine_defaults
}

configure_macbook_bootloader() {
  local luks_uuid=$1

  log "Configuring T2 encrypted boot"

  configure_limine_config write_macbook_limine_config "$luks_uuid"

  write_systemd_mkinitcpio_config 10-t2-encryption.conf <<'EOF'
MODULES=(t2bce_dma t2bce_core t2bce_vhci usbhid hid_apple)
EOF
  sudo install -d /etc/modules-load.d
  echo t2bce_vhci | sudo tee /etc/modules-load.d/t2.conf >/dev/null

  configure_limine_menu
}

install_macbook_bootloader() {
  local luks_uuid
  luks_uuid=$(encrypted_root_luks_uuid)

  configure_macbook_bootloader "$luks_uuid"
  validate_installed_limine_kernel_cmdlines "$luks_uuid" linux-t2 linux-t2-fallback
  install_limine_bootloader
}
