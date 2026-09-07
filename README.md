# laptop

Setup scripts for my personal and work Macs, Arch Linux ThinkPad,
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
| Raspberry Pi with Debian or Raspberry Pi OS | `./rpi.sh` |

The macOS and Arch profiles install 1Password CLI and call `op signin`. Set up
your CLI account before running, or configure it after the first sign-in failure
and rerun the profile. See [dotfiles and SSH keys](#dotfiles-and-ssh-keys) for the
required vault items.

## Changes to expect

These scripts apply my settings and can overwrite local configuration. Review the
chosen profile before running it.

- The Arch profile runs a full system upgrade and installs AUR packages through yay.
- The ThinkPad profile installs Hyprland and enables automatic desktop login as `tombell`.
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
| `desktop/` | Hyprland, greetd, fonts, and desktop applications |
| `thinkpad/` | ThinkPad additions, including Plymouth |

Put shared system services and command-line packages in `common/`, desktop
applications and appearance packages in `desktop/`, and hardware-specific
packages in the machine's directory. Machine additions
can be empty. Keep each package in one manifest, with each list sorted by
package name. The loader strips comments and blank lines, combines all three
sets, and removes duplicate names before installation. Direct use of the package
helper defaults to ThinkPad.

Limine, mkinitcpio, LUKS tools, and EFI partition tools live in `common/`.
The ThinkPad boot script retains its BusyBox initramfs with `udev` and `encrypt`.

The Pi uses `linux/debian/packages/apt.txt`; macOS uses `macos/Brewfile`.
Shared Linux configuration, including the desktop and login manager, lives in
`linux/shared/`, with boot and snapshot setup under `linux/thinkpad/`.

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
