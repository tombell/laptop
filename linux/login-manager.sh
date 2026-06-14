#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up greetd login manager…"

if ! grep -qi "hyprland" "/etc/greetd/config.toml" 2>/dev/null; then
  sudo tee /etc/greetd/config.toml <<EOF >/dev/null
[terminal]
vt = 1

[default_session]
command = "agreety --cmd /usr/bin/zsh"
user = "greeter"

[initial_session]
command = "uwsm start -- hyprland.desktop"
user = "tombell"
EOF
fi

sudo systemctl enable greetd.service
