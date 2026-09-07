#!/usr/bin/env bash
set -euo pipefail

echo "==> Enabling T2 fan control..."
sudo systemctl enable --now t2fanrd.service
