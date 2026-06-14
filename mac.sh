#!/usr/bin/env bash
set -euo pipefail

profile=${1:-}

case "$profile" in
personal)
  echo "==> Setting up personal macOS laptop…"
  dotfile_tags=(macos personal)
  ssh_keys=(Personal)
  restart_ssh_agent=false
  ;;
work)
  echo "==> Setting up work macOS laptop…"
  dotfile_tags=(macos work)
  ssh_keys=(Personal Work)
  restart_ssh_agent=true
  ;;
*)
  echo "Usage: $0 personal|work" >&2
  exit 1
  ;;
esac

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common/bootstrap.sh"
setup_laptop_root

source "$ROOT_DIR/common/rcm.sh"
source "$ROOT_DIR/common/ssh.sh"

source "$ROOT_DIR/macos/homebrew.sh"

ensure_dotfiles
setup_dotfiles "${dotfile_tags[@]}"

signin_1password
for ssh_key in "${ssh_keys[@]}"; do
  setup_ssh_key "Personal" "$ssh_key"
done

if [ "$restart_ssh_agent" = true ]; then
  killall ssh-agent 2>/dev/null || true
fi

source "$ROOT_DIR/macos/defaults.sh"
source "$ROOT_DIR/common/mise.sh"
