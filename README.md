# dotfiles

My Arch Linux configuration, managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap on a fresh Arch install

On a minimal Arch system (only `base` installed), as the regular wheel
user:

```sh
curl -fsSL https://raw.githubusercontent.com/sommerfelddev/dotfiles/master/bootstrap.sh | sh
```

This installs prerequisites, enables `%wheel` in sudoers, builds
`paru-bin` from the AUR, clones this repo to `~/dotfiles`, runs
`just init`, and — on EFI systems missing an Arch boot entry —
launches `create-efi`.

## Setup on an existing system

```sh
chezmoi init --source ~/dotfiles
chezmoi apply -v
```

