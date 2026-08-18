#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up greetd login manager…"

if ! grep -Fq 'command = "uwsm start -- hyprland.desktop >/dev/null 2>&1"' "/etc/greetd/config.toml" 2>/dev/null; then
  sudo tee /etc/greetd/config.toml <<EOF >/dev/null
[terminal]
vt = 1

[default_session]
command = "agreety --cmd /usr/bin/zsh"
user = "greeter"

[initial_session]
command = "uwsm start -- hyprland.desktop >/dev/null 2>&1"
user = "tombell"
EOF
fi

sudo systemctl enable greetd.service
