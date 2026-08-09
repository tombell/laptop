#!/usr/bin/env bash
set -euo pipefail

require_command herdr "install Herdr plugins"

install_herdr_plugin() {
  local plugin_id=$1
  local repository=$2
  shift 2

  if herdr plugin list --plugin "$plugin_id" --json |
    grep -Fq "\"plugin_id\":\"${plugin_id}\""; then
    echo "==> Herdr plugin ${plugin_id} already installed"
    return
  fi

  echo "==> Installing Herdr plugin ${plugin_id}…"
  herdr plugin install "$repository" "$@" --yes
}

install_herdr_plugin herdr-navigator thanhdat77/herdr-navigator --ref v0.3.5
install_herdr_plugin mroth.jj-status mroth/herdr-jj-status
