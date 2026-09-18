#!/usr/bin/env bash
set -euo pipefail

log "Configuring greetd"

greetd_config=$(cat <<'EOF'
[terminal]
vt = 1

[default_session]
command = "agreety --cmd /usr/bin/fish"
user = "greeter"

[initial_session]
command = "uwsm start -- hyprland.desktop >/dev/null 2>&1"
user = "tombell"
EOF
)

if ! cmp -s /etc/greetd/config.toml <<<"$greetd_config"; then
  sudo tee /etc/greetd/config.toml <<<"$greetd_config" >/dev/null
fi

sudo systemctl enable greetd.service
sudo systemctl set-default graphical.target
