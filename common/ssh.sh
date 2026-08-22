#!/usr/bin/env bash
set -euo pipefail

setup_ssh_key() {
  local vault=$1
  local name=$2
  local public_key="$HOME/.ssh/${name}.pub"
  local private_key="$HOME/.ssh/${name}"

  require_command op "set up SSH keys"

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if [ -e "$public_key" ] && [ -e "$private_key" ]; then
    echo "==> SSH keys for ${name} already exist"
    return
  fi

  echo "==> Setting up SSH keys for ${name}…"

  local temp_public_key temp_private_key
  temp_public_key="$(mktemp "${public_key}.XXXXXX")"
  temp_private_key="$(mktemp "${private_key}.XXXXXX")"

  trap 'rm -f "$temp_public_key" "$temp_private_key"' RETURN

  op read "op://${vault}/${name}/public key" >"$temp_public_key"
  chmod 644 "$temp_public_key"
  mv "$temp_public_key" "$public_key"

  op read "op://${vault}/${name}/private key" >"$temp_private_key"
  chmod 600 "$temp_private_key"
  mv "$temp_private_key" "$private_key"

  chmod 600 "$private_key"
  chmod 644 "$public_key"
}
