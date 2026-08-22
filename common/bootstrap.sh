#!/usr/bin/env bash
set -euo pipefail

setup_laptop_root() {
  ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
  export ROOT_DIR
  export LAPTOP_ROOT="$ROOT_DIR"
}

require_command() {
  local command_name=$1
  local reason=${2:-run this script}

  command -v "$command_name" >/dev/null || {
    echo "$command_name is required to ${reason}" >&2
    exit 1
  }
}

install_aur_package() {
  require_command yay "install AUR packages"
  yay -S --noconfirm --needed --removemake "$@"
}

ensure_dotfiles() {
  if [ ! -d "$HOME/.dotfiles" ]; then
    require_command git "clone dotfiles"
    git clone https://github.com/tombell/dotfiles.git "$HOME/.dotfiles"
  else
    echo "==> Updating dotfiles…"
    git -C "$HOME/.dotfiles" pull --ff-only
  fi
}

signin_1password() {
  require_command op "sign in to 1Password"
  eval "$(op signin)"
}
