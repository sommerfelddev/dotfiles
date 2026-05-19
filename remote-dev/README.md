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
- **Mason pip installs need a managed `python3.11`**: a handful of Mason
  packages (autotools-language-server, codespell, mdformat,
  nginx-language-server, systemdlint, yamllint) install themselves into
  per-pkg venvs via pip. Ubuntu 20.04's `/usr/bin/python3` is 3.8 — too
  old. `bootstrap.sh` runs `uv python install 3.11` (uv is in the nix
  profile) and symlinks the resulting binary to
  `~/.local/bin/python3.11`. The versioned name leaves
  `/usr/bin/python3` untouched. On an existing VM run
  `uv python install 3.11 && ln -sf "$(uv python find 3.11)" ~/.local/bin/python3.11`
  once, then `:MasonToolsInstall` (or `:MasonInstallAll`) in nvim.
- **`basedpyright` is provided by nix, not Mason**: its pypi distro
  pulls `nodejs-wheel-binaries`, which ships only `manylinux_2_28`
  Linux wheels. Neither Nix's python nor uv's standalone
  (`manylinux2014`-tagged) accepts those, so pip falls back to
  compiling Node 24 from source — which fails on Ubuntu 20.04's
  gcc 9.4 (needs gcc ≥10 for `-std=gnu++20`). `home.nix` adds
  `pkgs.basedpyright`; the matching AUR package (`basedpyright-bin`)
  is in `meta/base.txt` for Arch. `mason-tool-installer` no longer tries
  to install it (see `dot_config/nvim/lua/plugins/lsp.lua`).
- **Ubuntu apt collisions**: Nix-installed binaries appear first in
  PATH. The leaf-tools policy above exists precisely to keep this
  shadowing contained to harmless tools.

## Podman (rootless)

Nix can't manage setuid helpers, `/etc/subuid`/`/etc/subgid`, or kernel
cmdline. Do this once on the VM as root:

```sh
sudo apt install -y uidmap
grep "^$USER:" /etc/subuid /etc/subgid || \
  sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
```

Then (optional, **only** if you need rootless CPU/memory limits) enable
cgroups v2. Ubuntu 20.04 still defaults to v1; flipping this requires a
reboot and affects every workload on the box, so skip unless you have a
concrete need:

```sh
sudo sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"|GRUB_CMDLINE_LINUX_DEFAULT="\1 systemd.unified_cgroup_hierarchy=1"|' /etc/default/grub
sudo update-grub && sudo reboot
```

Verify:

```sh
podman info | grep -E 'cgroupVersion|graphDriverName|networkBackend'
# expected: graphDriverName: overlay, networkBackend: netavark
# cgroupVersion: v1 is fine — only blocks --memory/--cpus flags.
podman run --rm docker.io/library/alpine echo hi
```

The home-manager profile already installs `podman`, `crun`, `conmon`,
`netavark`, `aardvark-dns`, `slirp4netns`, and `passt`, and writes
sensible `~/.config/containers/{registries,storage,policy}.conf` files.

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
