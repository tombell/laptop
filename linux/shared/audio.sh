#!/usr/bin/env bash
set -euo pipefail

echo "==> Enabling PipeWire and WirePlumber..."

systemctl --user daemon-reload
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
