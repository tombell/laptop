#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common/bootstrap.sh"

case "$(uname -m)" in
x86_64)
  homebrew_prefix=/usr/local
  ;;
arm64)
  homebrew_prefix=/opt/homebrew
  ;;
*)
  die "Unsupported macOS architecture: $(uname -m)"
  ;;
esac

fish_shell="$homebrew_prefix/bin/fish"

if [ ! -x "$fish_shell" ]; then
  die "Homebrew fish was not found at $fish_shell"
fi

if ! grep -Fxq "$fish_shell" /etc/shells; then
  log "Adding Homebrew fish to /etc/shells"
  echo "$fish_shell" | sudo tee -a /etc/shells >/dev/null
fi

current_shell=$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')
if [ "$current_shell" != "$fish_shell" ]; then
  log "Setting login shell to Homebrew fish"
  chsh -s "$fish_shell"
fi
