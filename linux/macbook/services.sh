#!/usr/bin/env bash
set -euo pipefail

log "Enabling T2 fan control"
sudo systemctl enable --now t2fanrd.service
