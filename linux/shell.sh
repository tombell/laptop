#!/usr/bin/env bash
set -euo pipefail

current_shell=$(getent passwd "$(id -un)" | cut -d: -f7)
if [ "$current_shell" != "/usr/bin/fish" ]; then
  echo "==> Setting shell to fish…"
  chsh -s /usr/bin/fish
fi
