#!/usr/bin/env bash
set -euo pipefail

require_command herdr "install Herdr plugins"

echo "==> Installing Herdr plugins…"
herdr plugin install thanhdat77/herdr-navigator --ref v0.3.5 --yes
herdr plugin install mroth/herdr-jj-status --yes
