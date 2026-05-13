# remote-dev

Headless dev environment for an Ubuntu 22.04 VM I SSH into. Deployed with
Nix + Home-Manager. Shares the host's neovim, zellij, and zsh configs from
the same repo — no duplication.

## Bootstrap

On a fresh VM, as the dev user (must have sudo):

```sh
curl -fsSL https://raw.githubusercontent.com/ruifm/dotfiles/master/remote-dev/bootstrap.sh | sh
```

Then log out and back in. Run `nvim` once to let it fetch plugins from
GitHub on first launch.

## What it does

1. Installs Nix (Determinate Systems multi-user installer).
2. Clones this repo to `~/.local/share/dotfiles`.
3. Runs `home-manager switch --flake .../remote-dev#vm`, which:
   - Installs the CLI tool subset (see `home.nix`).
   - Symlinks `~/.config/{nvim,zellij,zsh,direnv,ghostty}` at the cloned
     working tree via `mkOutOfStoreSymlink`, so `git pull` is enough to
     pick up config edits — no rebuild needed for config-only changes.
   - Sets `ZDOTDIR=$HOME/.config/zsh` so the shared zshrc/zprofile load.
4. Appends the nix-store zsh to `/etc/shells` and `chsh`'s to it.

## Updating

```sh
cd ~/.local/share/dotfiles
git pull
nix run home-manager/master -- switch --flake ./remote-dev#vm
```

## Adding a tool

Edit `home.nix`, add to `home.packages`, then `home-manager switch`.

## Caveats

- **GPG / pass**: HM installs `gnupg` and `pass` but does _not_ import any
  private key. Bring your key separately if you need signed commits or
  `pass`-backed env vars on the VM.
- **Disk usage**: Nix store + nvim plugins consumes ~3-5 GB. Check the
  VM's root partition size first.
- **Network for first nvim launch**: `vim.pack.add` fetches plugins from
  GitHub on first start.
- **Ubuntu apt collisions**: Nix-installed binaries appear first in PATH.
  If you need a specific apt-version of something, install it manually
  and prefix with the full path.

## How it's wired

`home.nix` uses `config.lib.file.mkOutOfStoreSymlink` so the symlinks
point at the **live working tree** at `~/.local/share/dotfiles/...`, not
at copies in `/nix/store`. This means:

- Editing `dot_config/nvim/init.lua` in the cloned repo takes effect on
  the next `nvim` launch with no rebuild.
- `home-manager switch` only needs to re-run when adding/removing a
  package or changing what's symlinked.

The zsh plugins (`zsh-syntax-highlighting`, etc.) live in
`$HOME/.nix-profile/share/`. The shared `dot_zshrc` probes Arch system
paths first, then falls back to the nix-profile path, so the same file
works on both host and VM unchanged.
