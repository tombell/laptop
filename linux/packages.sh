#!/usr/bin/env bash
set -euo pipefail

sudo pacman -S --noconfirm --needed - <<EOF
bat
bluetui
brightnessctl
btop
dunst
fastfetch
fd
ffmpeg
fzf
ghostty
git
git-delta
github-cli
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
jujutsu
less
libyaml
man-db
mise
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
neovim-git
rcm
EOF
