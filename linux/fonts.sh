#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing fonts…"

yay -S --noconfirm --needed --removemake apple-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-iosevkaterm-nerd

FONT_VERSION=34.3.0

mkdir -p "$HOME/.local/share/fonts"
curl -Os "https://tombell-homebrew-assets.s3.us-east-1.amazonaws.com/IosevkaCustom-$FONT_VERSION.zip"
unzip IosevkaCustom-*.zip
mv IosevkaCustom.ttc "$HOME/.local/share/fonts/"
rm IosevkaCustom-*.zip
