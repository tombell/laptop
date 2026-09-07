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
- Both Arch profiles install Hyprland and enable automatic desktop login as `tombell`.
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

- UEFI boot and an installed `linux-t2` kernel with the `t2bce` drivers.
- The `arch-mact2` repository configured for T2 kernel, firmware, and support packages.
- A FAT EFI system partition mounted at `/boot`.
- Btrfs subvolume `@` mounted at `/` directly inside LUKS, without LVM.
- A separate Btrfs subvolume mounted at `/home` for Snapper.
- Working networking for package downloads.

It installs the same Hyprland desktop, greetd automatic login, fonts, GNOME
Keyring, and GTK settings as the ThinkPad. It applies the `linux` dotfile tag,
installs the `Personal` SSH key, and configures Snapper and mise tools.

The manifest maintains `linux-t2`, Apple wireless firmware, T2 audio profiles,
and `t2fanrd`. The initial kernel and working networking must already be present
so preflight checks and package downloads can run.

Boot setup uses mkinitcpio with the T2 keyboard drivers, the existing console
keymap, and `sd-encrypt`. It detects the LUKS UUID and builds Limine unified kernel
images with the T2 kernel parameters. Limine's package hooks maintain the EFI
loader on updates.

The profile overwrites `/etc/default/limine`,
`/etc/mkinitcpio.conf.d/10-t2-encryption.conf`, and `/etc/modules-load.d/t2.conf`.
It saves existing Limine defaults once as `/etc/default/limine.pre-macbook`.
Check other mkinitcpio drop-ins for settings that could override this configuration.

The script builds the boot images before installing Limine as the EFI fallback
loader. It leaves rebooting to you.

The boot setup has been tested on Mythra. Test boot and disk unlocking again
after changing the kernel, initramfs, or disk layout. Snapper configures
root and home snapshots; generating Limine snapshot entries requires separate
tooling.

## Arch networking and services

Both Arch profiles run `linux/arch/system.sh` after installing their packages.
It configures iwd, systemd-networkd, systemd-resolved, zram, Bluetooth, power
profiles, and the current user's PipeWire services. The MacBook also enables
`t2fanrd`, keeping any existing fan configuration.

Run as your regular user in a systemd login session, including SSH. To reapply
only this configuration after installing the packages:

```sh
bash linux/arch/system.sh
```

Networking uses DHCP, router-provided DNS, and mDNS on Wi-Fi and Ethernet.
Ethernet routes have priority over Wi-Fi, followed by mobile broadband. Existing
networkd configuration in `/etc`, `/run`, or `/usr/local/lib` is kept. If none
exists, the scripts install default `.network` files. Existing Wi-Fi credentials
in `/var/lib/iwd` are kept; use `iwctl` or Impala to join a new network.

The helper assumes the machine already uses iwd for Wi-Fi authentication and
systemd-networkd for IP configuration. Active network services are not restarted,
and new network definitions
apply when links next appear or after reboot. The resolver uses systemd-resolved's
stub; an existing different `/etc/resolv.conf` is backed up once as
`/etc/resolv.conf.pre-laptop`.

Zram defaults to zstd compression with half the usable RAM, capped at 4 GiB.
Existing generator configuration and masks are kept. A systemd service drop-in
disables zswap before zram0 starts, and the helper applies that setting immediately
if zram0 is already active. Reruns do not stop or resize active swap. Custom
configuration that does not generate zram0 swap is left in place.

Bluetooth and power-profiles-daemon are enabled as system services. PipeWire and
its PulseAudio compatibility sockets, plus WirePlumber, are enabled for the user
running setup. The services start immediately; no reboot is performed.

Verify with:

```sh
systemctl is-active iwd systemd-networkd systemd-resolved bluetooth power-profiles-daemon
systemctl --user is-active pipewire.socket pipewire-pulse.socket wireplumber
networkctl status wlan0
resolvectl query archlinux.org
swapon --show
zramctl
```

For the MacBook, also check `systemctl is-active t2fanrd`. Test audio output and
the microphone from the desktop; an active service alone does not verify sound.

## Raspberry Pi

The Pi installs git and rcm with apt, then clones and applies the base dotfiles
without tags, excluding `config/nvim`. It does not change the shell or install
SSH keys. The exclusion skips future installs; it does not remove existing
Neovim files or links.

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
networkctl status wlan0
resolvectl status
sudo snapper list-configs
```

Expect a T2 kernel, Btrfs subvolumes `@` and `@home`, a FAT `/boot`, an active LUKS
mapping, working networking, and Snapper configurations named `root` and `home`.

## Package lists

Arch packages live under `linux/arch/packages/`. Each directory contains
`pacman.txt` and `aur.txt`, with one package name per line. Add a short reason
after `#` for each pacman package. Both manifest types accept inline comments,
full-line comments, and blank lines:

```text
upower # Battery status service consumed by the Quickshell bar.
```

| Directory | Contents |
| --- | --- |
| `common/` | Shared system, networking, audio, and command-line packages |
| `desktop/` | Hyprland, greetd, fonts, and desktop applications for both Arch machines |
| `thinkpad/` | ThinkPad additions, including Plymouth |
| `macbook/` | MacBook additions for encrypted T2 boot |

Put shared system services and command-line packages in `common/`, desktop
applications and appearance packages in `desktop/`, and hardware-specific
packages in the machine's directory. Machine additions
can be empty. Keep each package in one manifest, with each list sorted by
package name. The loader strips comments and blank lines, combines all three
sets, and removes duplicate names before installation. Direct use of the package
helper defaults to ThinkPad.

Both Arch profiles share Limine, mkinitcpio, LUKS tools, and EFI partition tools.
Their initramfs configuration stays in the machine boot scripts: the ThinkPad
uses BusyBox with `udev` and `encrypt`, while the MacBook uses `systemd` and
`sd-encrypt` with the T2 drivers. `intel-ucode` and `systemd-ukify` remain in the
MacBook manifest. Ukify is the MacBook's current UKI builder choice; it does not
select the initramfs runtime.

The Pi uses `linux/debian/packages/apt.txt`; macOS uses `macos/Brewfile`.
Shared Linux configuration, including the desktop and login manager, lives in
`linux/shared/`, with boot setup under `linux/thinkpad/` and `linux/macbook/`. The MacBook reuses the ThinkPad
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

Run the isolated service-setup checks with `python3 -m unittest discover -s tests -v`.
They use temporary files and mocked system commands; they do not change the host.

The shell checks cover syntax and lint. Use the verification steps above to check an
installed system.
