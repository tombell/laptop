#!/usr/bin/env bash
set -euo pipefail

log "Configuring GNOME Keyring"

services_dir="$HOME/.local/share/dbus-1/services"
mkdir -p "$services_dir"

cat >"$services_dir/org.freedesktop.secrets.service" <<'EOF'
[D-BUS Service]
Name=org.freedesktop.secrets
Exec=/usr/bin/systemctl --user start gnome-keyring-daemon.service
EOF

systemctl --user enable --now gnome-keyring-daemon.service

if [ ! -f "$HOME/.local/share/keyrings/default" ]; then
  log "GNOME Keyring will ask you to create a default keyring when an application first stores a secret"
fi
