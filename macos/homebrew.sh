#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew…"
  command -v curl >/dev/null || {
    echo "curl is required to install Homebrew" >&2
    exit 1
  }
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v brew &>/dev/null; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

command -v brew >/dev/null || {
  echo "brew is required to install Homebrew formulae and casks" >&2
  exit 1
}

LAPTOP_ROOT="${LAPTOP_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

echo "==> Installing Homebrew formulae and casks…"
brew bundle --file "$LAPTOP_ROOT/macos/Brewfile"
