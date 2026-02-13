#!/usr/bin/env bash
set -euo pipefail

if command -v mise &>/dev/null; then
  echo "==> Installing mise tools…"
  mise install
fi
