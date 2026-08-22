#!/usr/bin/env bash
set -euo pipefail

profile=${1:-}

expected_hostname_for_profile() {
  case "$1" in
  personal) echo "Pyra" ;;
  work) echo "Haze" ;;
  server) echo "Brighid" ;;
  esac
}

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
server)
  echo "==> Setting up macOS server…"
  dotfile_tags=(server macos personal)
  ssh_keys=(Personal)
  restart_ssh_agent=false
  ;;
*)
  echo "Usage: $0 personal|work|server" >&2
  exit 1
  ;;
esac

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common/bootstrap.sh"
setup_laptop_root

computer_name=$(scutil --get ComputerName)
expected_hostname=$(expected_hostname_for_profile "$profile")
if [ "$computer_name" != "$expected_hostname" ]; then
  echo "WARNING: profile '$profile' expects ComputerName '$expected_hostname' but this machine is '$computer_name'" >&2
  echo "         the Brewfile gates package groups on hostname, packages may not match this profile" >&2
fi

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
  killall ssh-agent 2>/dev/null || true
fi

source "$ROOT_DIR/macos/defaults.sh"
source "$ROOT_DIR/common/mise.sh"
source "$ROOT_DIR/common/herdr.sh"
