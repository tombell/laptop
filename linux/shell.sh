#!/usr/bin/env bash
set -euo pipefail

if [ $SHELL != "/usr/bin/zsh" ]; then
  echo "==> Setting shell to zsh…"
  chsh -s /usr/bin/zsh
fi
