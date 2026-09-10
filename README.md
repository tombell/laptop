# laptop

Setup scripts for my personal and work Macs, Arch Linux ThinkPad, T2 MacBook Air,
and Debian Raspberry Pi.

## First run

Start with an installed OS, internet access, Git, and sudo access. Linux also
needs Bash. On a fresh Mac, run `xcode-select --install` to get Git through the
Command Line Tools.

```sh
git clone https://github.com/tombell/laptop.git ~/.laptop
cd ~/.laptop
```

Use the existing checkout if you already have one. Run `./setup --help` to list
the commands, or choose one below. Run setup as your regular user:

| Machine                                     | Command                                              |
| ------------------------------------------- | ---------------------------------------------------- |
| Personal Mac                                | `./setup macos personal`                             |
| Work Mac                                    | `./setup macos work`                                 |
| ThinkPad with Arch Linux                    | `./setup arch os thinkpad`, then `./setup arch user` |
| T2 MacBook Air with Arch Linux              | `./setup arch os macbook`, then `./setup arch user`  |
| Raspberry Pi with Debian or Raspberry Pi OS | `./setup debian rpi`                                 |

macOS and Arch OS setup install 1Password CLI. The macOS scripts and Arch user
setup call `op signin` to export SSH keys. Configure your CLI account before that
step. If sign-in fails, configure the account and rerun the relevant script. See
[dotfiles and SSH keys](#dotfiles-and-ssh-keys) for the vault items.

## Changes to expect

These scripts apply my settings, including overwriting local configuration. Read
the script for your machine before running it.

- Arch setup upgrades the system and installs AUR packages through yay.
- Both Arch machines use Hyprland with automatic desktop login as `tombell`.
- MacBook setup replaces the EFI fallback bootloader with Limine after building its boot images.
- macOS setup and Arch user setup change the login shell to fish and export SSH private keys to disk.

Reruns keep existing SSH keys and dotfiles checkouts, but reapply configuration.
Arch OS setup upgrades packages on each run. Arch user setup leaves system
packages, boot, snapshots, networking, and greetd alone.

## macOS

Both scripts install Homebrew if needed, install the packages in
`macos/Brewfile`, apply macOS defaults, install mise tools, and add the Herdr JJ
Status plugin. The Brewfile maps the Mac's ComputerName to a role (Pyra: personal, Brighid: mini,
Haze: work) and selects packages accordingly. Unknown computer names raise an error;
update the mapping in `macos/Brewfile` when adding or renaming a Mac.

Personal setup applies the `macos` and `personal` dotfile tags and installs the
`Personal` SSH key. Work setup applies `macos` and `work`, installs both
`Personal` and `Work` keys, and stops the existing ssh-agent process.

## Arch Linux

Run OS setup when preparing a machine, then rerun user setup whenever you
want to apply your configuration.

| Phase                                | Command                    | What it does                                                                        |
| ------------------------------------ | -------------------------- | ----------------------------------------------------------------------------------- |
| ThinkPad OS setup                    | `./setup arch os thinkpad` | Packages, bootloader, snapshots, networking, zram, system services, and greetd      |
| MacBook OS setup                     | `./setup arch os macbook`  | The same OS setup with T2 boot and fan control                                      |
| User configuration on either machine | `./setup arch user`        | Dotfiles, fonts, GNOME Keyring, GTK preferences, PipeWire, SSH keys, fish, and mise |

Run both phases as your regular user. OS setup uses sudo where needed. User
setup needs a running systemd user session, such as a desktop, TTY, or SSH login.
It assumes OS setup has installed the required packages.

Both OS profiles configure packages, boot, snapshots, and system services in that
order. The MacBook checks its boot prerequisites before installing packages.
greetd starts Hyprland through uwsm and logs in as `tombell`. Finish user setup
before rebooting into the desktop.

For routine configuration updates on either machine:

```sh
./setup arch user
```

User setup applies the `linux` dotfile tag and installs the `Personal` SSH key.
It skips 1Password sign-in when both key files already exist. It can still prompt
when changing your login shell to fish. mise installs the configured user tools.

### ThinkPad

The ThinkPad uses Limine and Plymouth. Boot setup assumes AMD graphics and an
encrypted Btrfs root, with mkinitcpio's BusyBox `udev` and `encrypt` hooks.

### T2 MacBook Air

The MacBook needs:

- UEFI boot and an installed `linux-t2` kernel with the `t2bce` drivers.
- The `arch-mact2` repository configured for T2 kernel, firmware, and support packages.
- A FAT EFI system partition mounted at `/boot`.
- Btrfs subvolume `@` mounted at `/` directly inside LUKS, without LVM.
- A separate Btrfs subvolume mounted at `/home` for Snapper.
- Working networking for package downloads.

The package list includes `linux-t2`, Apple wireless firmware, T2 audio profiles,
and `t2fanrd`. Install the initial T2 kernel and get networking working before
running the script.

Boot setup uses mkinitcpio with the T2 keyboard drivers, the existing console
keymap, and the systemd `sd-encrypt` hook. It reads the LUKS UUID and builds Limine
unified kernel images with the T2 kernel parameters. The shared AUR package list
installs `limine-tool`. Its pacman hooks rebuild UKIs after kernel and initramfs
dependency updates, remove entries for uninstalled kernels, and update the EFI
loader after Limine upgrades. No extra pacman hook or timer is needed.

Both Arch profiles apply the branding and palette from `linux/arch/limine.conf`,
with a one-second timeout and the first entry selected. Setup replaces those
shared menu options while preserving other settings and boot entries. It saves
an existing menu once as `/boot/limine.conf.pre-laptop`.
`limine-tool` maintains generated entries; kernel parameters belong in
`/etc/default/limine`, while menu settings such as `timeout` belong in
`/boot/limine.conf`.

For maintenance after the initial setup:

```sh
limine-list                         # Inspect the generated menu
sudo limine-update                  # Update the EFI loader and rebuild UKIs
sudo limine-mkinitcpio              # Rebuild UKIs after kernel command-line or hook changes
```

Do not rerun the full OS setup just to refresh Limine. When migrating from manual
entries, back up `/boot/limine.conf`, verify the generated UKI has booted, then
remove the obsolete entry with `sudo limine-entry-tool --remove-entry 'ENTRY NAME'`.
Check the default selection before reducing the menu timeout. Retire custom EFI
copy hooks once the packaged `80-limine-efi-deploy.hook` is in place.

The script overwrites `/etc/default/limine`,
`/etc/mkinitcpio.conf.d/10-t2-encryption.conf`, and `/etc/modules-load.d/t2.conf`.
It saves existing Limine defaults once as `/etc/default/limine.pre-macbook`.
Check other mkinitcpio drop-ins for settings that could override this configuration.

The script builds the boot images before installing Limine as the EFI fallback
loader. Reboot when you're ready to test it.

Boot and disk unlocking have been tested on Mythra. Retest after changing the
kernel, initramfs, or disk layout. Snapper configures root and home snapshots,
but adding them to the Limine menu needs separate tooling.

### Networking and services

Both OS scripts run `linux/arch/system.sh` to configure networking, zram,
Bluetooth, power profiles, and greetd. MacBook setup also enables `t2fanrd` and
keeps its existing fan configuration.

To rerun shared system service setup after installing packages, run as your
regular user with sudo access:

```sh
bash linux/arch/system.sh
```

The machines should already use iwd for Wi-Fi authentication and
systemd-networkd for IP configuration. Setup keeps existing networkd files in
`/etc`, `/run`, and `/usr/local/lib`. Otherwise, it installs DHCP defaults with
router-provided DNS and mDNS on Wi-Fi and Ethernet. Routes prefer Ethernet, then
Wi-Fi, then mobile broadband.

Setup keeps Wi-Fi credentials in `/var/lib/iwd`. Use `iwctl` or Impala to join a
new network. It starts network services without restarting active connections.
New network definitions apply when links next appear or after reboot.

DNS uses systemd-resolved's stub. Setup backs up a different `/etc/resolv.conf`
once to `/etc/resolv.conf.pre-laptop` before replacing it with the stub symlink.

Zram defaults to zstd compression with half the usable RAM, capped at 4 GiB.
Setup keeps existing generator configuration and masks, including configurations
that use a different device. A systemd service drop-in disables zswap before
zram0 starts. Setup also disables zswap if zram0 is already active, without
stopping or resizing swap.

OS setup enables Bluetooth and power-profiles-daemon. User setup enables the
PipeWire and PulseAudio compatibility sockets and WirePlumber for the current
user. These services start immediately.

Verify with:

```sh
systemctl is-active iwd systemd-networkd systemd-resolved bluetooth power-profiles-daemon
systemctl --user is-active pipewire.socket pipewire-pulse.socket wireplumber
networkctl status wlan0
resolvectl query archlinux.org
swapon --show
zramctl
```

On the MacBook, also run `systemctl is-active t2fanrd`. Test audio output and the
microphone from the desktop, even if the services are active.

## Raspberry Pi

Pi setup installs git and rcm with apt, then clones and applies the base dotfiles
without tags. It skips `config/nvim`, leaving existing Neovim files and links
alone. It also leaves the login shell and SSH keys alone.

## Verify setup

Open a new login session. On macOS and Arch, check the shell, sudo access, and
HTTPS connectivity:

```sh
echo "$SHELL"
sudo -v
curl --fail --head https://github.com
```

The shell path should end in `/fish`. On the Pi, check that rcm installed the
expected base dotfiles.

For the MacBook, reboot, select the internal EFI boot entry, and confirm that
Limine appears, the built-in keyboard unlocks LUKS, and your user can log in.
Then run:

```sh
uname -r
findmnt /
findmnt /home
findmnt /boot
sudo cryptsetup status cryptroot
networkctl status wlan0
resolvectl status
sudo snapper list-configs
```

Expect a T2 kernel, Btrfs subvolumes `@` and `@home`, a FAT `/boot`, an active LUKS
mapping, working networking, and Snapper configurations named `root` and `home`.

## Package lists

Arch package lists live in `linux/arch/packages/`. Each directory has a
`pacman.txt` and `aur.txt`, with one package per line. Add a short reason after
`#` for each pacman package. Both files accept inline comments, comment lines,
and blank lines:

```text
upower # Battery status service consumed by the Quickshell bar.
```

| Directory   | Contents                                                                 |
| ----------- | ------------------------------------------------------------------------ |
| `common/`   | Shared system, networking, audio, and command-line packages              |
| `desktop/`  | Hyprland, greetd, fonts, and desktop applications for both Arch machines |
| `thinkpad/` | ThinkPad additions, including Plymouth                                   |
| `macbook/`  | MacBook additions for encrypted T2 boot                                  |

Keep each package in one list and sort by package name. Machine lists can be
empty. The loader strips comments and blank lines, combines the common, desktop,
and machine lists, and removes duplicates before installing. Running the package
helper directly defaults to ThinkPad.

Both Arch machines share Limine, mkinitcpio, LUKS tools, and EFI partition tools.
The MacBook list includes `intel-ucode` and `systemd-ukify`. Ukify builds its
unified kernel images; the machine boot script chooses the initramfs hooks.

The Pi uses `linux/debian/packages/apt.txt`; macOS uses `macos/Brewfile`.

`setup` dispatches commands to the entry points in `profiles/arch/`,
`profiles/macos.sh`, and `profiles/rpi.sh`.
Shared Linux user configuration lives in `linux/shared/`. Shared Arch system
setup, including Snapper and greetd, lives in `linux/arch/`. Machine-specific
boot setup remains under `linux/thinkpad/` and `linux/macbook/`, alongside the
MacBook fan service setup.

## Dotfiles and SSH keys

The scripts clone [tombell/dotfiles](https://github.com/tombell/dotfiles) into
`~/.dotfiles` if needed, then apply the machine's tags with rcm.

SSH keys come from the `Personal` vault in 1Password. Items named `Personal` and
`Work` must contain `public key` and `private key` fields. Only the work macOS
profile needs the `Work` item.

Setup writes private keys to `~/.ssh/Personal` or `~/.ssh/Work` with mode `600`,
and public keys to matching `.pub` files with mode `644`. It copies the keys to
disk rather than using the 1Password SSH agent. Reruns keep existing files, so
replace them separately after rotating a key.

## Checks

Run from the repository root:

```sh
find . -type f \( -name '*.sh' -o -name setup \) -not -path './.git/*' -not -path './.jj/*' -exec shellcheck {} +
find . -type f \( -name '*.sh' -o -name setup \) -not -path './.git/*' -not -path './.jj/*' -exec bash -n {} \;
```

These checks cover shell syntax and lint. Use the verification commands above
and test the desktop and boot process on the machine.
