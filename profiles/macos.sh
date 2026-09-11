#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common/bootstrap.sh"
setup_laptop_root

profile=${1:-}

case "$profile" in
personal)
  dotfile_tags=(macos personal)
  ssh_keys=(Personal)
  restart_ssh_agent=false
  ;;
work)
  dotfile_tags=(macos work)
  ssh_keys=(Personal Work)
  restart_ssh_agent=true
  ;;
*)
  die "Usage: $0 personal|work"
  ;;
esac

log "Setting up $profile macOS laptop"

source "$ROOT_DIR/common/rcm.sh"
source "$ROOT_DIR/common/ssh.sh"

source "$ROOT_DIR/macos/homebrew.sh"

source "$ROOT_DIR/macos/shell.sh"

ensure_dotfiles
setup_dotfiles "${dotfile_tags[@]}"

signin_1password
for ssh_key in "${ssh_keys[@]}"; do
  setup_ssh_key "Personal" "$ssh_key"
done

if [ "$restart_ssh_agent" = true ]; then
  log "Stopping ssh-agent"
  killall ssh-agent 2>/dev/null || true
fi

source "$ROOT_DIR/macos/defaults.sh"
source "$ROOT_DIR/common/mise.sh"
source "$ROOT_DIR/common/herdr.sh"

log "macOS setup complete"
