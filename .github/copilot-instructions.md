# Copilot Instructions

## Repository overview

This is a personal dotfiles repository for an Arch Linux system. Configuration files are organized to mirror their filesystem targets and deployed via GNU Stow symlinks.

## Architecture

- `home/` mirrors `$HOME` — everything under it maps 1:1 to the home directory (e.g. `home/.config/nvim/` → `~/.config/nvim/`). Deployed with `stow -R --no-folding --adopt`.
- `etc/` contains system-level configs (`/etc/` targets) that can be deployed via stow symlinks — systemd units, pacman hooks, sysctl tunables, kernel module loading.
- `etc2/` also targets `/etc/` but holds configs for tools that refuse to follow symlinks (e.g. reflector). These must be manually copied to their target paths.
- `meta/` contains Arch Linux PKGBUILDs that bundle groups of packages into metapackages (e.g. `sommerfeld-base`, `sommerfeld-dev`). Each subdirectory is a standalone PKGBUILD recipe with a `.SRCINFO` and pre-built `.pkg.tar.zst` artifacts.

- `firefox/` contains Firefox hardening overrides and custom CSS.
- `create-efi.sh` is an interactive EFI boot entry creation script using `efibootmgr`.

## Window manager

Sway (Wayland compositor, i3-compatible). Config lives in `home/.config/sway/config`. Uses vanilla sway defaults for all standard WM operations with personal keybinds layered on top for media, volume, screenshots, lock screen, notifications, and display mode switching. The status bar is waybar (`home/.config/waybar/`), notifications via mako (`home/.config/mako/config`), and the launcher is fuzzel (`home/.config/fuzzel/fuzzel.ini`).

## Terminal multiplexer

Zellij is the terminal multiplexer. Config lives in `home/.config/zellij/config.kdl`. Most features are built-in defaults (session resurrection, mouse mode, clipboard). The `vim-zellij-navigator` WASM plugin enables seamless Ctrl h/j/k/l navigation between zellij panes and neovim splits (paired with `smart-splits.nvim` on the neovim side).

## Shell configuration

Zsh-only setup with three files:

- `home/.zshenv` — bootstrap: sets `ZDOTDIR=$HOME/.config/zsh` so all zsh config lives under XDG.
- `home/.config/zsh/.zprofile` — login shell: environment variables, XDG dirs, PATH, tool configs, secrets via `pass`.
- `home/.config/zsh/.zshrc` — interactive shell: options, completion, keybindings, aliases, plugins.

Additionally, `home/.config/sh/inputrc` provides readline config for non-zsh tools (python REPL, etc.).

## Key conventions

- **XDG compliance**: All tools are configured to respect XDG base directories. History files, caches, and data go to `$XDG_CACHE_HOME`, `$XDG_DATA_HOME`, etc. — never bare `~/` dotfiles when avoidable.
- **`doas` over `sudo`**: The system uses `doas` as the privilege escalation tool; `sudo` is aliased to `doas`.
- **GPG-signed commits**: All git commits and tags are signed. The GPG agent also handles SSH authentication.
- **Secrets via `pass`**: API keys and tokens are stored in the `pass` password manager and sourced into env vars at shell init, never hardcoded.
- **EditorConfig**: LF line endings, UTF-8, final newlines, trimmed trailing whitespace. Lua uses 2-space indentation with 80-char line limit. Makefiles use tabs.

## Editing guidelines

When modifying configs, preserve the stow-compatible directory structure — paths under `home/` must exactly match their `$HOME` targets. Do not introduce files that break the 1:1 mapping.

When editing shell config, all zsh configuration goes in `.config/zsh/` — do not create files in `home/.config/sh/` (only `inputrc` remains there).

## Keybinds reference

`KEYBINDS.md` at the repository root documents every non-default keybind across neovim, zellij, zsh, ghostty, and sway. Whenever you add, remove, or change a keybind in any of these tools, you must update `KEYBINDS.md` to reflect the change in the same commit.
