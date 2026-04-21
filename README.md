# dotfiles

My Arch Linux configuration, managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap on a fresh Arch install

`bootstrap.sh` assumes the Arch installation guide has been followed up
to the point of having a booted system with a wheel-group user. On a
minimal system (only `base` installed), prepare the user once as root:

```sh
pacman -S --needed sudo
useradd -m -G wheel -s /bin/bash <user>
passwd <user>
```

Then log in as that user and run:

```sh
curl -fsSL https://raw.githubusercontent.com/sommerfelddev/dotfiles/master/bootstrap.sh | sh
```

The script installs pacman prerequisites, enables `%wheel` in sudoers,
builds `paru-bin` from the AUR, clones this repo to `~/dotfiles`, runs
`just init`, enables recommended systemd units (fstrim, timesyncd,
resolved, reflector, paccache, pkgstats, acpid, cpupower, iwd, plus tlp
on laptops), refreshes the pacman mirrorlist, creates XDG user
directories, and — on EFI systems missing an Arch boot entry —
launches `create-efi`.

## Setup on an existing system

```sh
chezmoi init --source ~/dotfiles
chezmoi apply -v
```

## Layout

Everything is driven by [just](https://just.systems/) recipes against four parallel models:

| Directory                | Managed by                                    | Purpose                                                                                          |
| ------------------------ | --------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `dot_*`, `private_dot_*` | chezmoi                                       | Dotfiles deployed to `$HOME`. Prefixes: `dot_` → `.`, `private_` → `0600`, `executable_` → `+x`. |
| `meta/*.txt`             | `just install`, `just pkg-drift`              | Plain-text package lists (one per line, `#` comments). Groups: `base`, `dev`, `wayland`, etc.    |
| `systemd-units/*.txt`    | `just services-enable`, `just services-drift` | Units to enable, paired by name with a `meta/` group (`base.txt` ↔ `base.txt`).                  |
| `etc/`                   | `run_onchange_after_deploy-etc.sh.tmpl`       | System-level configs deployed to `/etc/` via a chezmoi onchange hook.                            |
| `firefox/`               | `run_onchange_after_deploy-firefox.sh.tmpl`   | LibreWolf `user-overrides.js` + `userChrome.css` (kept under the familiar `firefox/` name).      |

## Recipes at a glance

Run `just` or `just --list` for the full menu. Main recipes:

| Category      | Recipe                                                                    | Effect                                                                         |
| ------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Setup         | `just init`                                                               | First-time machine setup: chezmoi init, git hooks, apply, base group, services |
| Day-to-day    | `just sync`                                                               | `apply` + `fix` (deploy dotfiles + top up partially-installed groups)          |
|               | `just apply`                                                              | `chezmoi apply`                                                                |
|               | `just readd`                                                              | Pull live changes back into the repo (chezmoi re-add + `etc-readd`)            |
| Packages      | `just install GROUP [GROUP...]`                                           | Install the listed `meta/*.txt` groups                                         |
|               | `just install-all`                                                        | Install every group                                                            |
|               | `just add GROUP PKG`, `just remove GROUP PKG`                             | Edit a group list and install/remove                                           |
| Services      | `just services-enable`                                                    | Enable every unit in the enabled-group `systemd-units/*.txt` lists             |
| /etc          | `just etc-diff`, `just etc-readd`, `just etc-restore`, `just etc-untrack` | See /etc workflow below                                                        |
| Inspection    | `just status`                                                             | Combined dotfile + package + /etc + service drift                              |
|               | `just doctor`                                                             | Verify tooling for `just check` is installed                                   |
| Quality gates | `just fmt [PATH]`, `just check-fmt [PATH]`                                | Format / check formatting (all languages below)                                |
|               | `just lint [PATH]`                                                        | Run linters (selene, shellcheck, ruff, taplo)                                  |
|               | `just check [PATH]`                                                       | `check-fmt` + `lint` (the pre-commit hook and CI both run this)                |

`fmt` / `check-fmt` / `lint` cover: Lua (stylua, selene), shell (shfmt, shellcheck), Python (ruff), TOML (taplo), justfile (`just --fmt`), plus Markdown/JSON/YAML/CSS (prettier). Each accepts either no argument (whole repo) or a single file path.

## Drift workflow

Four sources of drift are tracked independently and combined by `just status`:

- **Dotfiles** (`chezmoi status`): live `$HOME` files differ from the repo. Resolve with `just apply` (repo → home), `just readd` (home → repo), `just diff`, or `just merge PATH`.
- **Packages** (`just pkg-drift`): installed but undeclared, or declared but missing. Resolve by adding to a `meta/` group (`just add GROUP PKG`) or by uninstalling.
- **/etc** (`just etc` / `just etc-diff`): installed package configs or user-created files in `/etc` that aren't in the repo. Resolve with `just etc-readd PATH` (track), `just etc-restore PATH` (revert to package default), or `just etc-untrack PATH`.
- **Services** (`just services-drift`): enabled units not in any `systemd-units/*.txt`, or declared units that aren't enabled.

## Git hooks

Activated by `just init` via `git config core.hooksPath .githooks`:

- `pre-commit` → `just check`. Blocks commits that fail formatting or linting. Bypass with `git commit --no-verify`.
- `post-commit` → `chezmoi apply`. Keeps `$HOME` in sync whenever a tracked file changes in the repo.

## Disaster recovery

The repo is enough to rebuild a machine's tooling and configuration, but not its **state** — back these up externally:

- GPG master key and subkeys (`gpg --export-secret-keys`, `gpg --export-ownertrust`). The agent also handles SSH auth, so this restores both.
- `~/.password-store/` — the `pass` store that feeds API keys/tokens into the shell at login.
- SSH private keys under `~/.ssh/id_*` (only `.pub` / config is in the repo).
- LibreWolf profile data (bookmarks, history, extension state) — only the hardening policy lives in `firefox/`.

Recovery on a fresh install: run `bootstrap.sh`, then `gpg --import` + `pass init <KEYID>`, restore `~/.password-store/`, drop SSH private keys into `~/.ssh/`, and restore the LibreWolf profile.
