#!/usr/bin/env bash
set -euo pipefail

FONT_VERSION=34.3.0

install_custom_iosevka() {
  local temp_dir
  local font_path="$HOME/.local/share/fonts/IosevkaCustom.ttc"
  local font_url

  if [ -e "$font_path" ]; then
    log "Keeping existing custom Iosevka font"
    return
  fi

  require_command curl "download custom Iosevka"
  require_command unzip "extract custom Iosevka"
  log "Installing custom Iosevka font"

  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN

  font_url="https://tombell-homebrew-assets.s3.us-east-1.amazonaws.com/IosevkaCustom-$FONT_VERSION.zip"

  mkdir -p "$HOME/.local/share/fonts"
  curl -fL "$font_url" -o "$temp_dir/IosevkaCustom.zip"
  unzip -q "$temp_dir/IosevkaCustom.zip" -d "$temp_dir"
  mv "$temp_dir/IosevkaCustom.ttc" "$font_path"

  rm -rf "$temp_dir"
  trap - RETURN

  if command -v fc-cache &>/dev/null; then
    fc-cache -f "$HOME/.local/share/fonts"
  fi
}

install_custom_iosevka
