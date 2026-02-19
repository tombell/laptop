#!/usr/bin/env bash
set -euo pipefail

setup_ssh_key() {
  local vault=$1
  local name=$2

  mkdir -p ~/.ssh

  echo "==> Setting up SSH keys for ${name}…"

  [ -e "~/.ssh/${name}.pub" ] || op read "op://${vault}/${name}/public key" >~/.ssh/${name}.pub
  [ -e "~/.ssh/${name}" ] || op read "op://${vault}/${name}/private key" >~/.ssh/${name}

  chmod 600 ~/.ssh/${name}
  chmod 600 ~/.ssh/${name}.pub
}
