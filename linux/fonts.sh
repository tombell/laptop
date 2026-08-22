#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing fonts…"

install_aur_package noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-iosevkaterm-nerd

FONT_VERSION=34.3.0
FONT_SHA256=f5bcafa9ad0c0dc31245bac8283430525702b8e566ee5afe7c428747b58c9118

install_custom_iosevka() {
  local temp_dir
  local font_path="$HOME/.local/share/fonts/IosevkaCustom.ttc"
  local font_url

  if [ -e "$font_path" ]; then
    return
  fi

  require_command curl "download custom Iosevka"

  require_command unzip "extract custom Iosevka"

  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN

  font_url="https://tombell-homebrew-assets.s3.us-east-1.amazonaws.com/IosevkaCustom-$FONT_VERSION.zip"

  mkdir -p "$HOME/.local/share/fonts"
  curl -fL "$font_url" -o "$temp_dir/IosevkaCustom.zip"

  echo "$FONT_SHA256  $temp_dir/IosevkaCustom.zip" | sha256sum --check --quiet

  unzip -q "$temp_dir/IosevkaCustom.zip" -d "$temp_dir"
  mv "$temp_dir/IosevkaCustom.ttc" "$font_path"

  rm -rf "$temp_dir"
  trap - RETURN

  if command -v fc-cache &>/dev/null; then
    fc-cache -f "$HOME/.local/share/fonts"
  fi
}

install_custom_iosevka
