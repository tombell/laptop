#!/usr/bin/env bash
set -euo pipefail

log "Enabling Bluetooth and power profiles"

sudo systemctl enable --now bluetooth.service power-profiles-daemon.service
