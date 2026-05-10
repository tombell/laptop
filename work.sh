#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up work macOS laptop…"

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export LAPTOP_ROOT="$ROOT_DIR"

source "$ROOT_DIR/common/rcm.sh"
source "$ROOT_DIR/common/ssh.sh"

source "$ROOT_DIR/macos/homebrew.sh"

if [ ! -d "$HOME/.dotfiles" ]; then
  command -v git >/dev/null || {
    echo "git is required to clone dotfiles" >&2
    exit 1
  }

  git clone https://github.com/tombell/dotfiles.git "$HOME/.dotfiles"
fi

setup_dotfiles macos work

command -v op >/dev/null || {
  echo "op is required to sign in to 1Password" >&2
  exit 1
}

eval "$(op signin)"
setup_ssh_key "Personal" "Personal"
setup_ssh_key "Personal" "Work"
killall ssh-agent 2>/dev/null || true

source "$ROOT_DIR/macos/defaults.sh"
source "$ROOT_DIR/common/mise.sh"
