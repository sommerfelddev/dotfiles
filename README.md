# dotfiles

My Arch Linux configuration, managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap on a fresh Arch install

As the regular wheel user (not root), on a minimal Arch system (only
`base` installed):

```sh
curl -fsSL https://raw.githubusercontent.com/sommerfelddev/dotfiles/master/bootstrap.sh | sh
```

This installs pacman prerequisites, enables `%wheel` in sudoers, builds
`paru-bin` from the AUR, clones this repo to `~/dotfiles`, runs
`just init`, enables recommended systemd units (fstrim, timesyncd,
resolved, reflector, paccache, pkgstats, acpid, cpupower, iwd, plus tlp
on laptops), refreshes the pacman mirrorlist, creates XDG user
directories, and — on EFI systems missing an Arch boot entry —
launches `create-efi`.

The script assumes the Arch installation guide has already been
followed up to the point of creating a wheel-group user and booting
into their session.

## Setup on an existing system

```sh
chezmoi init --source ~/dotfiles
chezmoi apply -v
```

