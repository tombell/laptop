#!/usr/bin/env bash
set -euo pipefail

configure_limine_menu() (
  log "Configuring Limine menu"

  local menu_file
  menu_file=$(mktemp)
  trap 'rm -f "$menu_file"' EXIT

  # Replace shared menu options, preserving other settings and all boot entries.
  sudo sh -c '
    cd /boot || exit 1
    if [ -e limine.conf ] || [ -L limine.conf ]; then
      cat limine.conf
    fi
  ' | awk '
    FILENAME != "-" {
      print
      if ($0 ~ /^#/) comments[$0] = 1
      if ($0 ~ /^[a-z_]+:/) {
        split($0, option, ":")
        managed[option[1]] = 1
      }
      next
    }
    /^\// { in_entries = 1 }
    !in_entries && /^[[:space:]]*$/ { next }
    {
      if (!in_entries) sub(/^[[:space:]]+/, "", $0)
      split($0, option, ":")
      if (in_entries || (!(option[1] in managed) && !($0 in comments))) print
    }
  ' "$ROOT_DIR/linux/arch/limine.conf" - >"$menu_file" || return 1

  sudo install -m 0644 "$menu_file" /boot/limine.conf
)
