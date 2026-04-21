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

| Directory                | Managed by                                  | Purpose                                                                                          |
| ------------------------ | ------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `dot_*`, `private_dot_*` | chezmoi                                     | Dotfiles deployed to `$HOME`. Prefixes: `dot_` → `.`, `private_` → `0600`, `executable_` → `+x`. |
| `meta/*.txt`             | `just pkg-apply`, `just pkg-status`         | Plain-text package lists (one per line, `#` comments). Groups: `base`, `dev`, `wayland`, etc.    |
| `systemd-units/*.txt`    | `just unit-apply`, `just unit-status`       | Units to enable, paired by name with a `meta/` group (`base.txt` ↔ `base.txt`).                  |
| `etc/`                   | `run_onchange_after_deploy-etc.sh.tmpl`     | System-level configs deployed to `/etc/` via a chezmoi onchange hook.                            |
| `firefox/`               | `run_onchange_after_deploy-firefox.sh.tmpl` | LibreWolf `user-overrides.js` + `userChrome.css` (kept under the familiar `firefox/` name).      |

## Recipes at a glance

Run `just` or `just --list` for the full menu. Recipes follow a `DOMAIN-VERB` scheme across four domains (`dotfiles`, `etc`, `pkg`, `unit`) with chezmoi-aligned verbs (`add`, `forget`, `re-add`, `apply`, `diff`, `merge`, `status`). Top-level dispatchers sniff argument shape and delegate.

| Category      | Recipe                                     | Effect                                                                             |
| ------------- | ------------------------------------------ | ---------------------------------------------------------------------------------- |
| Setup         | `just init`                                | First-time setup: chezmoi init, git hooks, apply, base packages, curated units     |
| Day-to-day    | `just sync`                                | `apply` + `pkg-fix` + `unit-apply` (full reconcile)                                |
|               | `just apply`                               | `chezmoi apply` — atomically deploys dotfiles AND /etc                             |
|               | `just re-add [PATH]`                       | Pull live changes back into the repo (dotfiles + /etc)                             |
| Add / forget  | `just add PATH`                            | Dispatches to `dotfiles-add` (path) or `etc-add` (`/etc/...`)                      |
|               | `just add GROUP NAME…`                     | Dispatches to `pkg-add` (bare names) or `unit-add` (ends in `.service`/`.timer`/…) |
|               | `just forget …`                            | Same shape as `add`; delegates to the right `*-forget`                             |
| Packages      | `just pkg-apply [GROUP…]`                  | Install listed groups, or every group if none given                                |
|               | `just pkg-fix`                             | Top up missing packages in already-adopted groups                                  |
|               | `just pkg-list [GROUP]`                    | Show per-group install coverage                                                    |
| Units         | `just unit-apply`                          | Enable every unit in the adopted `systemd-units/*.txt` lists                       |
|               | `just unit-list [GROUP]`                   | List curated units with their state                                                |
| /etc          | `just etc-diff`, `just etc-re-add`,        | See /etc workflow below                                                            |
|               | `just etc-restore`, `just etc-untrack`     |                                                                                    |
| Inspection    | `just status`                              | Combined dotfile + /etc + package + unit drift                                     |
|               | `just diff [PATH]`, `just merge [PATH]`    | Dispatch to `dotfiles-*` or `etc-*` by path                                        |
|               | `just doctor`                              | Verify tooling for `just check` is installed                                       |
| Quality gates | `just fmt [PATH]`, `just check-fmt [PATH]` | Format / check formatting (all languages below)                                    |
|               | `just lint [PATH]`                         | Run linters (selene, shellcheck, ruff, taplo)                                      |
|               | `just check [PATH]`                        | `check-fmt` + `lint` (the pre-commit hook and CI both run this)                    |

`fmt` / `check-fmt` / `lint` cover: Lua (stylua, selene), shell (shfmt, shellcheck), Python (ruff), TOML (taplo), justfile (`just --fmt`), plus Markdown/JSON/YAML/CSS (prettier). Each accepts either no argument (whole repo) or a single file path.

## Drift workflow

Four sources of drift are tracked independently and combined by `just status`:

- **Dotfiles** (`just dotfiles-status`): live `$HOME` files differ from the repo. Resolve with `just apply` (repo → home), `just re-add PATH` (home → repo), `just diff PATH`, or `just merge PATH`.
- **Packages** (`just pkg-status`): installed but undeclared, or declared but missing. Resolve by adding to a `meta/` group (`just add GROUP PKG`) or uninstalling.
- **/etc** (`just etc-status` / `just etc-diff`): modified package configs or user-created files in `/etc` that aren't in the repo. Resolve with `just etc-re-add PATH` (track), `just etc-restore PATH` (revert to package default), or `just etc-untrack PATH`.
- **Units** (`just unit-status`): enabled units not in any `systemd-units/*.txt`, or declared units that aren't enabled.

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
