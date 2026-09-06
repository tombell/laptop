# laptop

Setup scripts for my personal and work Macs, Arch Linux ThinkPad, T2 MacBook Air,
and Debian Raspberry Pi.

## Usage

Choose the script for the machine and run it as your regular user. Linux setup
requires Bash and sudo access. The scripts configure an existing OS installation.

| Machine | Command |
| --- | --- |
| Personal Mac | `./personal.sh` |
| Work Mac | `./work.sh` |
| ThinkPad with Arch Linux | `./thinkpad.sh` |
| T2 MacBook Air with Arch Linux | `./macbook.sh` |
| Raspberry Pi with Debian or Raspberry Pi OS | `./rpi.sh` |

The macOS wrappers call `./mac.sh personal` or `./mac.sh work`.
Each Linux script selects its own distro and machine configuration.

## macOS

Both profiles install Homebrew and the packages in `macos/Brewfile`, set fish as
the login shell, apply macOS defaults, install mise tools, and add the Herdr JJ
Status plugin. The Brewfile selects some packages using the Mac's ComputerName.

The personal profile applies the `macos` and `personal` dotfile tags and installs
the `Personal` SSH key. The work profile applies `macos` and `work`, installs both
`Personal` and `Work` keys, and stops the existing ssh-agent process.

## ThinkPad

The ThinkPad profile updates Arch, installs yay, and installs shared packages
plus the ThinkPad additions. It configures Limine, Plymouth, Snapper, fonts,
GNOME Keyring, fish, GTK settings, and mise tools. It also applies the `linux`
dotfile tag and installs the `Personal` SSH key through 1Password CLI.

The boot configuration assumes AMD graphics and an encrypted Btrfs root using
the mkinitcpio `encrypt` hook. The profile installs Hyprland and enables greetd
with automatic login as `tombell` through uwsm.

## T2 MacBook Air

Run this profile on an existing T2 Arch installation with:

- UEFI boot and a `linux-t2` kernel that provides the `t2bce` drivers.
- A FAT EFI system partition mounted at `/boot`.
- Btrfs subvolume `@` mounted at `/` directly inside LUKS, without LVM.
- A separate Btrfs subvolume mounted at `/home` for its Snapper configuration.
- Working T2 firmware, networking, audio, and fan configuration.

The profile installs shared packages plus the MacBook additions for a
terminal-only system. It applies the `linux` dotfile tag, installs the `Personal`
SSH key through 1Password CLI, and configures Snapper, fish, and mise tools.

Boot setup uses mkinitcpio with the T2 keyboard drivers, the existing console
keymap, and `sd-encrypt`. It detects the root volume's LUKS UUID and configures
Limine to build unified kernel images with the T2 kernel parameters.

Before replacing the EFI fallback loader, the script saves an existing GRUB
loader from `/boot/EFI/BOOT/BOOTX64.EFI` to `/boot/EFI/GRUB/BOOTX64.EFI` and adds
a GRUB recovery entry. It builds the boot images before installing Limine at
`/boot/EFI/BOOT/BOOTX64.EFI`, then enables automatic EFI loader updates.

The profile writes these configuration files on each run:

- `/etc/default/limine`
- `/etc/mkinitcpio.conf.d/10-t2-encryption.conf`
- `/etc/modules-load.d/t2.conf`

It saves an existing Limine defaults file once as
`/etc/default/limine.pre-macbook`. Review other mkinitcpio drop-ins before running,
since they can override the generated settings.

The script leaves rebooting to you. Verify a Limine boot before removing GRUB.
For recovery from the live ISO, mount the EFI partition and copy its saved
`EFI/GRUB/BOOTX64.EFI` back to `EFI/BOOT/BOOTX64.EFI`.

The MacBook script and Limine boot still need a hardware test. Snapper setup
creates root and home configurations; adding snapshot entries to Limine requires
separate snapshot synchronization tooling.

## Raspberry Pi

The Pi profile installs git and rcm with apt before cloning and applying the base
dotfiles. It uses no dotfile tags and leaves desktop, shell, and SSH key setup to
you.

## Package lists

Arch packages live under `linux/arch/packages/`. Each directory contains
`pacman.txt` and `aur.txt`, with one package name per line.

| Directory | Contents |
| --- | --- |
| `common/` | Packages used by both Arch machines |
| `thinkpad/` | ThinkPad additions, including the desktop |
| `macbook/` | MacBook additions for encrypted T2 boot |

Add a package to `common/` when both machines need it. Otherwise, add it to the
machine's directory. Empty lists are allowed for machine additions.

Both Arch scripts select their package profile explicitly. The package helper
combines the shared and machine lists, removes duplicate names, and reads both
package sources before starting installation. Direct use of the helper defaults
to the ThinkPad profile.

The Pi uses `linux/debian/packages/apt.txt`.
macOS packages live in `macos/Brewfile`.

## Dotfiles and SSH keys

The scripts clone [tombell/dotfiles](https://github.com/tombell/dotfiles) into
`~/.dotfiles` when it is missing, then apply the selected tags with rcm.

The macOS and Arch profiles sign in to 1Password CLI. Their SSH keys come from
the `Personal` vault, using items named `Personal` or `Work` with `public key` and
`private key` fields. Have your 1Password CLI account configured before running.
Existing SSH key files are kept.

## Script layout

| Directory | Purpose |
| --- | --- |
| `common/` | Bootstrap, dotfiles, SSH, mise, and Herdr helpers |
| `macos/` | Homebrew, shell, and macOS defaults |
| `linux/shared/` | Font, GUI, keyring, and shell configuration |
| `linux/arch/` | pacman, yay, and Arch package lists |
| `linux/debian/` | apt setup and the Pi package list |
| `linux/macbook/` | T2 encrypted-boot configuration |
| `linux/thinkpad/` | ThinkPad boot and login setup, plus Snapper setup reused by the MacBook |

## Rerunning

Package installation skips installed packages where supported, and dotfiles are
cloned only when missing. Configuration steps can overwrite local settings.
The Arch profiles also update the system on each run.

## Checks

Run ShellCheck and Bash's syntax checker from the repository root:

```sh
find . -type f -name '*.sh' -not -path './.git/*' -not -path './.jj/*' -exec shellcheck {} +
find . -type f -name '*.sh' -not -path './.git/*' -not -path './.jj/*' -exec bash -n {} \;
```

These checks do not run the setup scripts or test booting the installed system.
