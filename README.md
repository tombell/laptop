# laptop

Setup scripts for my personal and work Macs, Arch Linux ThinkPad, T2 MacBook Air,
and Debian Raspberry Pi.

## First run

Start with an installed OS, internet access, Git, and sudo access. Linux profiles
also require Bash. On a fresh Mac, `xcode-select --install` provides Git through
the Command Line Tools.

```sh
git clone https://github.com/tombell/laptop.git ~/.laptop
cd ~/.laptop
```

If the repo already exists, use that checkout. Choose one script and run it as
your regular user:

| Machine | Command |
| --- | --- |
| Personal Mac | `./personal.sh` |
| Work Mac | `./work.sh` |
| ThinkPad with Arch Linux | `./thinkpad.sh` |
| T2 MacBook Air with Arch Linux | `./macbook.sh` |
| Raspberry Pi with Debian or Raspberry Pi OS | `./rpi.sh` |

The macOS and Arch profiles install 1Password CLI and call `op signin`. Set up
your CLI account before running, or configure it after the first sign-in failure
and rerun the profile. See [dotfiles and SSH keys](#dotfiles-and-ssh-keys) for the
required vault items.

## Changes to expect

These scripts apply my settings and can overwrite local configuration. Review the
chosen profile before running it.

- Both Arch profiles run a full system upgrade and install AUR packages through yay.
- ThinkPad setup installs Hyprland and enables automatic desktop login as `tombell`.
- MacBook setup replaces the EFI fallback bootloader with Limine after building its boot images.
- macOS and Arch setup change the login shell to fish and export SSH private keys to disk.

Reruns keep existing SSH keys and clone dotfiles only when missing. Configuration
steps still run, and Arch still performs a system upgrade.

## macOS

Both profiles install the packages in `macos/Brewfile`, apply macOS defaults,
install mise tools, and add the Herdr JJ Status plugin. Homebrew is installed
when missing. The Brewfile selects some packages using the Mac's ComputerName.

The personal profile applies the `macos` and `personal` dotfile tags and installs
the `Personal` SSH key. The work profile applies `macos` and `work`, installs both
`Personal` and `Work` keys, and stops the existing ssh-agent process.

## ThinkPad

The ThinkPad profile configures Limine, Plymouth, Snapper, fonts, GNOME Keyring,
GTK settings, and mise tools. It applies the `linux` dotfile tag and installs the
`Personal` SSH key.

Its boot configuration assumes AMD graphics and an encrypted Btrfs root using
the mkinitcpio `encrypt` hook. greetd starts Hyprland through uwsm.

## T2 MacBook Air

The MacBook profile requires:

- UEFI boot and a `linux-t2` kernel with the `t2bce` drivers.
- A FAT EFI system partition mounted at `/boot`.
- Btrfs subvolume `@` mounted at `/` directly inside LUKS, without LVM.
- A separate Btrfs subvolume mounted at `/home` for Snapper.
- Working T2 firmware, networking, audio, and fan configuration.

It installs terminal-only packages, applies the `linux` dotfile tag, installs the
`Personal` SSH key, and configures Snapper and mise tools.

Boot setup uses mkinitcpio with the T2 keyboard drivers, the existing console
keymap, and `sd-encrypt`. It detects the LUKS UUID and builds Limine unified kernel
images with the T2 kernel parameters. Limine's package hooks maintain the EFI
loader on updates.

The profile overwrites `/etc/default/limine`,
`/etc/mkinitcpio.conf.d/10-t2-encryption.conf`, and `/etc/modules-load.d/t2.conf`.
It saves existing Limine defaults once as `/etc/default/limine.pre-macbook`.
Check other mkinitcpio drop-ins for settings that could override this configuration.

When an existing GRUB fallback loader and configuration are present, the script
saves the loader at `/boot/EFI/GRUB/BOOTX64.EFI` and adds a GRUB recovery menu entry.
Keep GRUB until Limine has booted successfully. The script leaves rebooting to you.

The MacBook script and Limine boot still need a hardware test. Snapper configures
root and home snapshots; generating Limine snapshot entries requires separate
tooling.

## Raspberry Pi

The Pi installs git and rcm with apt, then clones and applies the base dotfiles
without tags. It does not change the shell or install SSH keys.

## Verify setup

Open a new login session. On macOS and Arch, check the shell, sudo access, and
HTTPS connectivity:

```sh
echo "$SHELL"
sudo -v
curl --fail --head https://github.com
```

The shell should end in `/fish`. On the Pi, check that your expected base dotfiles
were installed instead.

For the MacBook, reboot, select the internal EFI boot entry, and confirm that
Limine appears, the built-in keyboard unlocks LUKS, and your user can log in.
Then run:

```sh
uname -r
findmnt /
findmnt /home
findmnt /boot
sudo cryptsetup status cryptroot
nmcli general status
sudo snapper list-configs
```

Expect a T2 kernel, Btrfs subvolumes `@` and `@home`, a FAT `/boot`, an active LUKS
mapping, working networking, and Snapper configurations named `root` and `home`.

## Restore GRUB on the MacBook

If Limine cannot boot, start the T2 live ISO and open a root Bash shell. Identify
the internal EFI partition:

```sh
lsblk -o NAME,SIZE,FSTYPE,PARTLABEL,MOUNTPOINTS
```

The commands below use `/dev/nvme0n1p1`, the EFI partition in the two-partition
MacBook layout. Confirm it is the internal FAT partition and is unmounted, or
replace the device path. This restores the saved EFI loader; it requires the
existing GRUB configuration and kernel files to remain intact.

```bash
(
  set -e
  mkdir -p /mnt/esp
  mount /dev/nvme0n1p1 /mnt/esp
  test -s /mnt/esp/EFI/GRUB/BOOTX64.EFI
  cp /mnt/esp/EFI/GRUB/BOOTX64.EFI /mnt/esp/EFI/BOOT/BOOTX64.EFI
  sync
  umount /mnt/esp
)
```

After the commands succeed, reboot and select the internal EFI boot entry.
Once back in the installed system, stop Limine's update hooks from replacing the
restored loader while you investigate:

```sh
sudo sed -i 's/^ENABLE_LIMINE_FALLBACK=yes$/ENABLE_LIMINE_FALLBACK=no/' /etc/default/limine
```

## Package lists

Arch packages live under `linux/arch/packages/`. Each directory contains
`pacman.txt` and `aur.txt`, with one package name per line:

| Directory | Contents |
| --- | --- |
| `common/` | Packages used by both Arch machines |
| `thinkpad/` | ThinkPad additions, including the desktop |
| `macbook/` | MacBook additions for encrypted T2 boot |

Put shared packages in `common/` and other packages in the machine's directory.
Machine additions can be empty. The loader combines both lists and removes
duplicate names. Direct use of the package helper defaults to ThinkPad.

The Pi uses `linux/debian/packages/apt.txt`; macOS uses `macos/Brewfile`.
Shared Linux configuration lives in `linux/shared/`, with boot and login setup
under `linux/thinkpad/` and `linux/macbook/`. The MacBook reuses the ThinkPad
Snapper script.

## Dotfiles and SSH keys

The scripts clone [tombell/dotfiles](https://github.com/tombell/dotfiles) into
`~/.dotfiles` when missing, then apply the profile's tags with rcm.

SSH keys come from the `Personal` vault in 1Password. Items named `Personal` and
`Work` must contain `public key` and `private key` fields. Only the work macOS
profile needs the `Work` item.

The helper exports private keys to `~/.ssh/Personal` or `~/.ssh/Work` with mode
`600`, and public keys to the corresponding `.pub` files with mode `644`.
These are local key files, not references to the 1Password SSH agent. Existing
files are kept, so rerunning does not refresh a rotated key.

## Checks

Run from the repository root:

```sh
find . -type f -name '*.sh' -not -path './.git/*' -not -path './.jj/*' -exec shellcheck {} +
find . -type f -name '*.sh' -not -path './.git/*' -not -path './.jj/*' -exec bash -n {} \;
```

These check shell syntax and lint. Use the verification steps above to check an
installed system.
