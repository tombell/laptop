#!/usr/bin/env bash
set -euo pipefail

setup_ssh_key() {
  local vault=$1
  local name=$2
  local public_key="$HOME/.ssh/${name}.pub"
  local private_key="$HOME/.ssh/${name}"

  command -v op >/dev/null || {
    echo "op is required to set up SSH keys" >&2
    exit 1
  }

  mkdir -p "$HOME/.ssh"

  echo "==> Setting up SSH keys for ${name}…"

  [ -e "$public_key" ] || op read "op://${vault}/${name}/public key" >"$public_key"
  [ -e "$private_key" ] || op read "op://${vault}/${name}/private key" >"$private_key"

  chmod 600 "$private_key"
  chmod 644 "$public_key"
}
