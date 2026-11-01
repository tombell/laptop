#!/usr/bin/env bash
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/../common/bootstrap.sh"

xcode_app_id=497799835

if [ ! -d /Applications/Xcode.app ]; then
  require_command mas "install Xcode"
  log "Installing Xcode from the App Store"
  if ! sudo mas get "$xcode_app_id"; then
    log "Warning: Xcode was not installed. Sign in to the App Store, then run: sudo mas get $xcode_app_id"
  fi
fi
