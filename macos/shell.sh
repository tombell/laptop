#!/usr/bin/env bash
set -euo pipefail

case "$(uname -m)" in
x86_64)
  homebrew_prefix=/usr/local
  ;;
arm64)
  homebrew_prefix=/opt/homebrew
  ;;
*)
  echo "Unsupported macOS architecture: $(uname -m)" >&2
  exit 1
  ;;
esac

fish_shell="$homebrew_prefix/bin/fish"

if [ ! -x "$fish_shell" ]; then
  echo "Homebrew fish was not found at $fish_shell" >&2
  exit 1
fi

if ! grep -Fxq "$fish_shell" /etc/shells; then
  echo "==> Adding Homebrew fish to /etc/shells…"
  echo "$fish_shell" | sudo tee -a /etc/shells >/dev/null
fi

current_shell=$(dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}')
if [ "$current_shell" != "$fish_shell" ]; then
  echo "==> Setting shell to Homebrew fish…"
  chsh -s "$fish_shell"
fi
