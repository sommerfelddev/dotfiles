# remote-dev

Headless dev environment for an Ubuntu 22.04 VM I SSH into. Deployed with
Nix + Home-Manager. Shares the host's neovim, zellij, and zsh configs from
the same repo — no duplication.

## Bootstrap

On a fresh VM, as the dev user (must have sudo):

```sh
curl -fsSL https://raw.githubusercontent.com/sommerfelddev/dotfiles/master/remote-dev/bootstrap.sh | sh
```

Then log out and back in. Run `nvim` once to let it fetch plugins from
GitHub on first launch.

## What it does

1. Installs Nix (Determinate Systems multi-user installer).
2. Clones this repo to `~/.local/share/dotfiles`.
3. Runs `home-manager switch --flake .../remote-dev#vm`, which:
   - Installs the CLI tool subset (see `home.nix`).
   - Symlinks `~/.config/{nvim,zellij,zsh,direnv,ghostty,git}` and
     `~/.ssh/config` at the cloned working tree via
     `mkOutOfStoreSymlink`, so `git pull` is enough to pick up config
     edits — no rebuild needed for config-only changes.
   - Sets `ZDOTDIR=$HOME/.config/zsh` so the shared zshrc/zprofile load.
4. Appends the nix-store zsh to `/etc/shells` and `chsh`'s to it.

## Updating after a dotfiles change

Run from `~/.local/share/dotfiles/remote-dev`:

```sh
just update     # pull + home-manager switch (handles everything)
```

Or piece-by-piece if you know which one you need:

```sh
just pull       # config-only changes (nvim/zellij/zsh/git/ssh): no rebuild needed
just switch     # rebuild home-manager from the current checkout
```

> `just update` runs `pull` then `switch`. The home-manager invocation
> uses `--impure --flake '.#vm' -b backup`; the single-quotes around the
> flake ref matter because our zsh enables `extendedglob`, which would
> otherwise interpret `.#vm` as a glob pattern.

## Adding a tool

Edit `home.nix`, add to `home.packages`, then `just switch` (or `just update`).

## Single-shell policy (leaf tools only)

Nix on this VM carries **leaf CLI tools** plus **editor/AI-agent
runtimes**, and nothing else. Specifically forbidden in `home.packages`
because they would shadow Ubuntu's via `PATH` and silently break builds
against the system sysroot/libc/CI: `cc`, `c++`, `gcc`, `g++`, `clang`,
`clang++`, `ld`, `make`, `cmake`, `ninja`, `meson`, `pkg-config`,
`autoconf`, `automake`, `python`, `python3`, `pip`, `cargo`, `rustc`,
`go`. The system `python3` (`/usr/bin/python3`) stays the default
interpreter for project builds.

Explicit carve-outs (used only by Mason/editor/AI agents, never by the
project build):

- `nodejs` — `node`/`npm`/`npx` for npm-based LSPs.
- `uv` — `uv`/`uvx` for Python LSPs in isolated venvs. `uv` does NOT
  install a `python3` in PATH; it manages its own interpreters under
  `~/.local/share/uv/`. System `python3` is untouched.
- `clang-tools` — `clang-format`, `clang-tidy`, `clangd` only (no
  compiler driver).

If a project needs a newer build toolchain, drop a `flake.nix` +
`.envrc` in that project tree (direnv + nix-direnv is already wired
up). Don't add it to `home.nix`.

## Commit signing on the VM (SSH-format, no GPG secrets)

GPG private keys never leave the host. Commits on the VM are signed
with the **forwarded SSH agent** in SSH-signature format, using the
authentication subkey gpg-agent already exposes via `ssh-add -L`.

One-time setup on the VM:

```sh
mkdir -p ~/.config/git

# allowed_signers: maps your committer email to the SSH pubkey of the
# auth subkey. Adjust the grep if you have multiple keys.
printf '%s %s\n' \
  "$(git config user.email)" \
  "$(ssh-add -L | head -n1)" \
  > ~/.config/git/allowed_signers

# Machine-local git override (NOT tracked in dotfiles).
cat > ~/.config/git/config.local <<EOF
[gpg]
    format = ssh
[gpg "ssh"]
    allowedSignersFile = ~/.config/git/allowed_signers
[user]
    signingkey = $(ssh-add -L | head -n1 | awk '{print $1" "$2}')
EOF
```

The tracked `dot_config/git/config` ends with `[include] path =
~/.config/git/config.local`, so the override is picked up
automatically (and silently ignored on machines that don't have it).

Required on the **host's** `~/.ssh/config` for the VM `Host` block:

```
ForwardAgent yes
```

Verify on the VM after SSH-ing in:

```sh
ssh-add -L                 # should list your auth pubkey(s)
git commit --allow-empty -m test
git log --show-signature -1
```

## Caveats

- **GPG / pass**: HM installs `gnupg` and `pass` but does _not_ import
  any private key. Don't try; use SSH-format signing via the forwarded
  agent instead (see above).
- **Disk usage**: Nix store + nvim plugins consumes ~3-5 GB. Check the
  VM's root partition size first.
- **Network for first nvim launch**: `vim.pack.add` fetches plugins
  from GitHub on first start. Mason will also fetch LSP servers using
  `nodejs`/`uv` from this profile.
- **Ubuntu apt collisions**: Nix-installed binaries appear first in
  PATH. The leaf-tools policy above exists precisely to keep this
  shadowing contained to harmless tools.

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
