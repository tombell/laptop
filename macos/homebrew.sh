#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew…"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "==> Installing Homebrew formulae and casks…"
brew bundle --file "$(dirname "$0")/macos/Brewfile"
