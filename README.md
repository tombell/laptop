# laptop

Scripts for setting up my personal/work macOS laptops, macOS server, Arch Linux ThinkPad, and Raspberry Pi.

## Usage

```sh
./personal.sh
./work.sh
./server.sh
./thinkpad.sh
./macbook.sh
./rpi.sh
```

The macOS wrappers delegate to the profile-aware entrypoint:

```sh
./mac.sh personal
./mac.sh work
./mac.sh server
```

## Checks

Run ShellCheck and Bash's syntax checker directly:

```sh
find . -type f -name '*.sh' -not -path './.git/*' -not -path './.jj/*' -exec shellcheck {} +
find . -type f -name '*.sh' -not -path './.git/*' -not -path './.jj/*' -exec bash -n {} \;
```

## What each profile does

### Personal macOS

- Installs Homebrew if needed
- Installs packages from `macos/Brewfile`
- Sets Homebrew's `fish` as the user shell
- Installs Herdr Navigator v0.3.5 and Herdr JJ Status
- Clones `https://github.com/tombell/dotfiles.git` into `~/.dotfiles` if needed
- Runs `rcup` with `macos` and `personal` tags
- Signs in to 1Password CLI
- Installs the `Personal` SSH key
- Applies macOS defaults
- Installs mise tools

### Work macOS

- Installs Homebrew if needed
- Installs packages from `macos/Brewfile`
- Sets Homebrew's `fish` as the user shell
- Installs Herdr Navigator v0.3.5 and Herdr JJ Status
- Clones dotfiles if needed
- Runs `rcup` with `macos` and `work` tags
- Signs in to 1Password CLI
- Installs the `Personal` and `Work` SSH keys
- Restarts `ssh-agent`
- Applies macOS defaults
- Installs mise tools

### macOS Server

- Installs Homebrew if needed
- Installs packages from `macos/Brewfile`
- Sets Homebrew's `fish` as the user shell
- Clones dotfiles if needed
- Runs `rcup` with `macos`, `personal`, and `server` tags
- Signs in to 1Password CLI
- Installs the `Personal` SSH key
- Applies macOS defaults
- Installs mise tools

### Raspberry Pi

Assumes Debian (including Raspberry Pi OS), with `sudo` available.

- Updates apt package indexes and installs `git` and `rcm` from `linux/debian/packages/apt.txt`
- Clones dotfiles if needed
- Runs `rcup` with no tags to install the base dotfiles

### ThinkPad Linux

Assumes Arch Linux.

- Configures pacman and updates the system
- Installs `yay`
- Installs packages from:
  - `linux/arch/packages/common/{pacman,aur}.txt`
  - `linux/arch/packages/thinkpad/{pacman,aur}.txt`
- Clones dotfiles if needed
- Runs `rcup` with the `linux` tag
- Signs in to 1Password CLI
- Installs the `Personal` SSH key
- Configures bootloader, snapshots, fonts, greetd, shell, GUI settings, and mise tools

### MacBook Air Linux

Run `./macbook.sh` as your regular user on an existing T2 Arch installation.
Requires `sudo`, `linux-t2` with the `t2bce` drivers, UEFI boot, a FAT EFI
partition mounted at `/boot`, and Btrfs subvolume `@` mounted at `/` directly
inside LUKS. This is post-install configuration; it does not partition disks.

- Combines shared packages from `linux/arch/packages/common/` with terminal-only additions from `linux/arch/packages/macbook/`
- Keeps the installed T2 kernel, firmware, networking, audio, and fan configuration
- Configures mkinitcpio with T2 keyboard drivers and `sd-encrypt`, preserving the console keymap
- Configures Limine with UKIs and the encrypted-root and T2 kernel parameters
- Saves the existing GRUB EFI loader as `/boot/EFI/GRUB/BOOTX64.EFI` and adds a recovery menu entry
- Builds boot images before installing Limine at `/boot/EFI/BOOT/BOOTX64.EFI`
- Enables Limine's package hooks to maintain the EFI fallback loader on updates
- Reuses the Btrfs root/home Snapper configuration, Linux dotfiles, 1Password CLI SSH setup, fish, and mise
- Does not install a desktop, display manager, Plymouth, or graphical keyring

The profile manages `/etc/default/limine` and
`/etc/mkinitcpio.conf.d/10-t2-encryption.conf`. An existing Limine defaults file
is saved once as `/etc/default/limine.pre-macbook`. Review any other local
mkinitcpio drop-ins before running. Run from a normal login session, with
1Password CLI sign-in available. The script neither reboots nor removes GRUB.
Verify a Limine boot before removing GRUB. From the live ISO, its saved EFI
loader can also be copied back to `EFI/BOOT/BOOTX64.EFI` on the mounted ESP.
Snapper configuration does not add snapshot entries to Limine; that requires
separate snapshot synchronization tooling.

## Script layout

- `common/`: cross-platform dotfiles, SSH, mise, and bootstrap helpers
- `linux/shared/`: distro-agnostic configuration for fonts, GUI settings, keyring, and shell; no package installation
- `linux/arch/`: pacman configuration, AUR helper, and Arch package manifests
- `linux/debian/`: apt package installation and Debian package manifest
- `linux/macbook/`: T2 MacBook encrypted-boot configuration
- `linux/thinkpad/`: machine-specific bootloader, snapshots, and login-manager configuration

`thinkpad.sh` and `rpi.sh` explicitly select their distro setup and configuration.
Shared scripts are opt-in: the headless Pi does not run desktop or shell configuration.
Package manifests supply prerequisites before configuration scripts run. Arch profiles
combine `common/` with either `thinkpad/` or `macbook/`, removing duplicate package
names before installation. Both entrypoints explicitly select their profile; the
package helper defaults to ThinkPad when used directly. Add packages used by both
machines to `common/` and machine-specific additions to the matching profile.
Debian's manifest contains only the Pi's dotfile prerequisites.
The Pi keeps untagged dotfiles, while the ThinkPad uses the `linux` tag.

## Assumptions

- Dotfiles live at `https://github.com/tombell/dotfiles.git`
- 1Password CLI is available before SSH keys are configured
- SSH keys are stored in 1Password items named after the key, with fields:
  - `public key`
  - `private key`
- macOS package selection is controlled by hostname in `macos/Brewfile`
- Linux entrypoints target the ThinkPad and T2 MacBook Arch installs and the Debian Raspberry Pi; they do not auto-detect distributions

## Re-running

The scripts are intended to be safe to rerun. Package installs use `--needed` where available, dotfiles are cloned only when missing, and SSH keys are only written when the target files do not already exist.
