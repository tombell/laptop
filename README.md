# laptop

Setup scripts for my Macs and Linux laptops

## Get started

Start with a working OS, internet access, Git, and sudo access. Run setup as your regular user. These scripts apply my personal settings.

On a fresh Mac, install the Command Line Tools first:

```sh
xcode-select --install
```

Clone the repository, or use your existing checkout:

```sh
git clone https://github.com/tombell/laptop.git ~/.laptop
cd ~/.laptop
```

## Run setup

| Machine                                     | Command                    |
| ------------------------------------------- | -------------------------- |
| Personal Mac                                | `./setup macos personal`   |
| Work Mac                                    | `./setup macos work`       |
| ThinkPad with Arch Linux                    | `./setup arch os thinkpad` |
| MacBook Air (T2) with Arch Linux            | `./setup arch os macbook`  |
| Raspberry Pi with Debian or Raspberry Pi OS | `./setup debian rpi`       |

On either Arch laptop, finish with user setup before rebooting:

```sh
./setup arch user
```

Have your 1Password account ready for SSH key setup on macOS and Arch. Follow the prompts, then start a new login session when setup finishes.

To reapply your Arch user settings later, run `./setup arch user` again. Run `./setup --help` to see all setup commands.
