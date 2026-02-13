#!/usr/bin/env bash
set -euo pipefail

sudo pacman -S --noconfirm --needed - <<EOF
bluetui
brightnessctl
btop
dunst
fastfetch
fd
ffmpeg
fzf
ghostty
gnome-themes-extra
greetd
hypridle
hyprland
hyprlock
hyprpaper
hyprshot
imagemagick
impala
imv
less
libyaml
man-db
mise
neovim
openssh
polkit-gnome
qt6ct
ripgrep
rofi
unzip
usage
uwsm
waybar
wireless-regdb
wiremix
xdg-desktop-portal-gtk
xdg-desktop-portal-hyprland
xdg-user-dirs
zoxide
zsh
zsh-autosuggestions
zsh-completions
EOF

yay -S --noconfirm --needed --removemake - <<EOF
1password
1password-cli
google-chrome
rcm
EOF
