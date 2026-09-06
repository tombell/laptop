#!/usr/bin/env bash
set -euo pipefail

LAPTOP_ROOT="${LAPTOP_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"

echo "==> Installing Debian packages…"

mapfile -t apt_packages <"$LAPTOP_ROOT/linux/debian/packages/apt.txt"
sudo apt-get update
sudo apt-get install -y "${apt_packages[@]}"
