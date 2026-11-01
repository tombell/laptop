#!/usr/bin/env bash
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/../common/bootstrap.sh"

set_computer_name() {
  local name=$1
  local key

  for key in ComputerName HostName LocalHostName; do
    if [ "$(scutil --get "$key" 2>/dev/null || true)" != "$name" ]; then
      log "Setting $key to $name"
      sudo scutil --set "$key" "$name"
    fi
  done
}
