#!/usr/bin/env bash
set -euo pipefail

if command -v mise &>/dev/null; then
  log "Installing mise tools"
  mise install
fi
