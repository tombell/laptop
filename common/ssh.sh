#!/usr/bin/env bash
set -euo pipefail

setup_ssh_key() (
  local vault=$1
  local name=$2
  local public_key="$HOME/.ssh/${name}.pub"
  local private_key="$HOME/.ssh/${name}"
  local staging_dir

  umask 077
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  log "Configuring SSH key ${name}"

  if [[ ! -e "$public_key" || ! -e "$private_key" ]]; then
    signin_1password || return
    staging_dir=$(mktemp -d "$HOME/.ssh/.key.XXXXXX") || return
    trap 'rm -rf "$staging_dir"' EXIT

    if [[ ! -e "$public_key" ]]; then
      op read "op://${vault}/${name}/public key" >"$staging_dir/public" || return
    fi
    if [[ ! -e "$private_key" ]]; then
      op read "op://${vault}/${name}/private key" >"$staging_dir/private" || return
    fi

    if [[ -f "$staging_dir/private" ]]; then
      mv -n "$staging_dir/private" "$private_key" || return
    fi
    if [[ -f "$staging_dir/public" ]]; then
      mv -n "$staging_dir/public" "$public_key" || return
    fi
  fi

  chmod 600 "$private_key"
  chmod 644 "$public_key"
)
