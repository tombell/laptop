#!/usr/bin/env bash
set -euo pipefail

echo "==> Enabling Bluetooth, power profiles, and PipeWire..."

sudo systemctl enable --now bluetooth.service power-profiles-daemon.service
systemctl --user daemon-reload
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
