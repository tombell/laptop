#!/usr/bin/env bash
set -euo pipefail

if command -v gsettings &>/dev/null; then
  log "Configuring GTK interface options"
  gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
fi
