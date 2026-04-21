# Copilot Instructions

## Repository overview

This is a personal dotfiles repository for an Arch Linux system, managed with [chezmoi](https://www.chezmoi.io/).

## Architecture

The repo root is a chezmoi source directory. Files targeting `$HOME` use chezmoi naming conventions (`dot_`, `private_`, `executable_` prefixes). Deploy with `chezmoi apply -v`.

- `dot_config/`, `private_dot_gnupg/`, `private_dot_ssh/`, etc. — chezmoi source state mapping to `$HOME`. Prefix meanings: `dot_` → leading `.`, `private_` → restricted permissions, `executable_` → `+x` bit.
- `etc/` contains system-level configs (`/etc/` targets) — systemd units, pacman hooks, sysctl tunables, kernel module loading. Deployed by `run_onchange_after_deploy-etc.sh.tmpl`.
- `meta/` contains plain text package lists for Arch Linux (one package per line, `#` comments). Each `.txt` file represents a group (e.g. `base.txt`, `dev.txt`, `wayland.txt`). Install with `just install base dev` or `just install-all`. Detect drift with `just status`.
- `firefox/` contains Firefox/LibreWolf hardening overrides (`user-overrides.js`) and custom CSS (`chrome/userChrome.css`). Deployed by `run_onchange_after_deploy-firefox.sh.tmpl`.
- `create-efi.sh` is an interactive EFI boot entry creation script using `efibootmgr`.
- `.chezmoiignore` excludes non-home files (`etc/`, `meta/`, `firefox/`, docs) from deployment to `$HOME`.
- `.githooks/` contains git hooks (notably `post-commit` which runs `chezmoi apply`). Activate with `just install-hooks`.
- `justfile` provides recipes: `install-hooks`, `apply`, `install`, `install-all`, `add`, `status`, `groups`.

## Window manager

Sway (Wayland compositor, i3-compatible). Config lives in `dot_config/sway/config`. Uses vanilla sway defaults for all standard WM operations with personal keybinds layered on top for media, volume, screenshots, lock screen, notifications, and display mode switching. The status bar is waybar (`dot_config/waybar/`), notifications via mako (`dot_config/mako/config`), and the launcher is fuzzel (`dot_config/fuzzel/fuzzel.ini`).

## Terminal multiplexer

Zellij is the terminal multiplexer. Config lives in `dot_config/zellij/config.kdl`. Most features are built-in defaults (session resurrection, mouse mode, clipboard). The `vim-zellij-navigator` WASM plugin enables seamless Ctrl h/j/k/l navigation between zellij panes and neovim splits (paired with `smart-splits.nvim` on the neovim side).

## Shell configuration

Zsh-only setup with three files:

- `dot_zshenv` — bootstrap: sets `ZDOTDIR=$HOME/.config/zsh` so all zsh config lives under XDG.
- `dot_config/zsh/dot_zprofile` — login shell: environment variables, XDG dirs, PATH, tool configs, secrets via `pass`.
- `dot_config/zsh/dot_zshrc` — interactive shell: options, completion, keybindings, aliases, plugins.

Additionally, `dot_config/sh/inputrc` provides readline config for non-zsh tools (python REPL, etc.).

## Key conventions

- **XDG compliance**: All tools are configured to respect XDG base directories. History files, caches, and data go to `$XDG_CACHE_HOME`, `$XDG_DATA_HOME`, etc. — never bare `~/` dotfiles when avoidable.
- **`doas` over `sudo`**: The system uses `doas` as the privilege escalation tool; `sudo` is aliased to `doas`.
- **GPG-signed commits**: All git commits and tags are signed. The GPG agent also handles SSH authentication.
- **Secrets via `pass`**: API keys and tokens are stored in the `pass` password manager and sourced into env vars at shell init, never hardcoded.
- **EditorConfig**: LF line endings, UTF-8, final newlines, trimmed trailing whitespace. Lua uses 2-space indentation with 80-char line limit. Makefiles use tabs.

## Editing guidelines

When modifying configs, use chezmoi naming conventions: `dot_` prefix for dotfiles, `private_` for restricted-permission dirs/files, `executable_` for scripts. To add a new config file, use `chezmoi add <target-path>`.

The `run_onchange_after_*` scripts are chezmoi templates (`.tmpl`) that embed `sha256sum` hashes of the files they deploy. Chezmoi only re-runs them when file content changes. When adding a new file to `etc/` or `firefox/`, you must add its hash comment and file path to the corresponding run script.

When editing shell config, all zsh configuration goes in `dot_config/zsh/` — do not create files in `dot_config/sh/` (only `inputrc` remains there).

## Keybinds reference

`KEYBINDS.md` at the repository root documents every non-default keybind across neovim, zellij, zsh, ghostty, and sway. Whenever you add, remove, or change a keybind in any of these tools, you must update `KEYBINDS.md` to reflect the change in the same commit.
