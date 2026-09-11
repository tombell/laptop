#!/usr/bin/env bash
set -euo pipefail

configure_limine_menu() {
  log "Configuring Limine menu"

  local menu_file existing_menu=/dev/null
  menu_file=$(mktemp)

  if [ -f /boot/limine.conf ]; then
    existing_menu=/boot/limine.conf
    if [ ! -f /boot/limine.conf.pre-laptop ]; then
      sudo cp /boot/limine.conf /boot/limine.conf.pre-laptop
    fi
  fi

  # Replace shared menu options, preserving other settings and all boot entries.
  awk '
    NR == FNR {
      print
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
      if (in_entries || !(option[1] in managed)) print
    }
  ' "$ROOT_DIR/linux/arch/limine.conf" "$existing_menu" > "$menu_file" || {
    rm -f "$menu_file"
    return 1
  }
  sudo install -m 0644 "$menu_file" /boot/limine.conf
  rm -f "$menu_file"
}
