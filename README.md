# laptop

Scripts for setting up my personal/work macOS laptops, macOS server, Arch Linux ThinkPad, and Raspberry Pi.

## Usage

```sh
./personal.sh
./work.sh
./server.sh
./thinkpad.sh
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
shellcheck {,common/,linux/,linux/thinkpad/,macos/}*.sh
bash -n {,common/,linux/,linux/thinkpad/,macos/}*.sh
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

- Clones dotfiles if needed
- Runs `rcup` with no tags to install the base dotfiles

### ThinkPad Linux

Assumes Arch Linux.

- Configures pacman and updates the system
- Installs `yay`
- Installs packages from:
  - `linux/packages/pacman.txt`
  - `linux/packages/aur.txt`
- Clones dotfiles if needed
- Runs `rcup` with the `linux` tag
- Signs in to 1Password CLI
- Installs the `Personal` SSH key
- Configures bootloader, snapshots, fonts, greetd, shell, GUI settings, and mise tools

## Assumptions

- Dotfiles live at `https://github.com/tombell/dotfiles.git`
- 1Password CLI is available before SSH keys are configured
- SSH keys are stored in 1Password items named after the key, with fields:
  - `public key`
  - `private key`
- macOS package selection is controlled by hostname in `macos/Brewfile`
- Linux setup is intended for the ThinkPad Arch install, not a generic Linux machine

## Re-running

The scripts are intended to be safe to rerun. Package installs use `--needed` where available, dotfiles are cloned only when missing, and SSH keys are only written when the target files do not already exist.
