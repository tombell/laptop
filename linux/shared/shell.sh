#!/usr/bin/env bash
set -euo pipefail

if [ "${SHELL:-}" != "/usr/bin/fish" ]; then
  log "Setting login shell to fish"
  chsh -s /usr/bin/fish
fi
