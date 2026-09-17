# Dotfiles Repository Notes

This is a personal dotfiles repository for an Arch Linux host and an Ubuntu
remote-dev VM, plus a Canonical Ubuntu GNOME laptop. The repo root is a chezmoi
source directory.

## Layout

- Home-directory targets use chezmoi naming conventions: `dot_` for leading
  dots, `private_` for restricted permissions, and `executable_` for scripts.
- `etc/` contains host `/etc` source files deployed by the repo's onchange
  script.
- `meta/` contains flat package lists. Keep one package per line and use short
  comments only when they help future maintenance.
- `systemd-units/` tracks enabled system and user units in plain text.
- `firefox/` and `thunderbird/` hold browser and mail profile source files.
- `nix/` owns Home-Manager profiles and the repo development shell.
- `.githooks/` contains hooks installed by the repo recipes.

## Package Ownership

- Pacman owns system-coupled pieces.
- Home-Manager owns user-leaf tools.
- Project compilers, linkers, and language runtimes belong in per-project Nix
  dev shells via direnv.
- Do not add global Home-Manager packages that shadow the system build
  toolchain (`gcc`, `clang`, `ld`, `make`, `pkg-config`, language runtimes,
  etc.) unless the user explicitly asks for that tradeoff.
- On the Arch host, keep GPU/OpenGL Wayland apps in pacman unless they have
  been smoke-tested from Nix against the host graphics stack.

## Chezmoi Roles

- `host`: user dotfiles plus host-only `/etc`, Firefox/LibreWolf, and Flatpak
  integration hooks.
- `vm`: user dotfiles, skipping host-only `/etc` and Firefox/LibreWolf hooks.
- `canonical`: an explicit home-file allowlist, shared Nix CLI tools, and GNOME.
  Package lists are in `meta/canonical/`. Do not deploy the Arch `etc/` tree,
  personal keys, Sway units, or pass-secret-service. Keep authd/GDM, GNOME
  Keyring, and company policies intact. See `docs/canonical-laptop.md`.
- Machine-specific dotfile behavior belongs in chezmoi templates keyed by
  `machineRole`.
- The VM Home-Manager profile installs packages and session variables only. Do
  not add ordinary dotfiles to `xdg.configFile` or `home.file` in `nix/vm.nix`.

## Config Conventions

- Keep comments in config files operational. Prefer section labels and short
  purpose notes over migration history.
- Add new user config through chezmoi source naming.
- Zsh config lives in `dot_config/zsh/` and `dot_zshenv`. Do not add new shell
  config under `dot_config/sh/`; only `inputrc` belongs there.
- `KEYBINDS.md` documents non-default keybinds across neovim, zellij, zsh,
  ghostty, and sway. Update it in the same change when keybinds change.
