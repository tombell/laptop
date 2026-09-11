#!/usr/bin/env bash
set -euo pipefail

source "$ROOT_DIR/linux/arch/limine-menu.sh"

write_mkinitcpio_config() {
  local config_name=$1

  log "Configuring mkinitcpio"
  sudo install -d /etc/mkinitcpio.conf.d
  sudo tee "/etc/mkinitcpio.conf.d/$config_name" >/dev/null
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
