# nix

Home-Manager profiles for the Arch host (`host.nix`) and the Ubuntu
remote-dev VM (`vm.nix`), both layered on top of `common.nix`. Shares
the same nvim, zellij, and zsh configs from the same repo — no
duplication across machines.

## Bootstrap

**Host (Arch)**: managed by the top-level `bootstrap.sh` in the repo
root (installs nix + runs `home-manager switch --flake .../nix#host`
as part of `just init`).

**VM (Ubuntu)**: as the dev user (must have sudo):

```sh
curl -fsSL https://raw.githubusercontent.com/sommerfelddev/dotfiles/master/nix/bootstrap.sh | sh
```

Then log out and back in. Run `nvim` once to let it fetch plugins from
GitHub on first launch.

## What the VM bootstrap does

1. Installs Nix (Determinate Systems multi-user installer).
2. Clones this repo to `~/.local/share/dotfiles`.
3. Runs `home-manager switch --flake .../nix#vm`, which:
   - Installs the CLI tool subset (see `common.nix` + `vm.nix`).
   - Symlinks `~/.config/{nvim,zellij,zsh,direnv,ghostty,git}` and
     `~/.ssh/config` at the cloned working tree via
     `mkOutOfStoreSymlink`, so `git pull` is enough to pick up config
     edits — no rebuild needed for config-only changes.
   - Sets `ZDOTDIR=$HOME/.config/zsh` so the shared zshrc/zprofile load.
4. Appends the nix-store zsh to `/etc/shells` and `chsh`'s to it.

## Updating after a dotfiles change

Run from `~/.local/share/dotfiles/nix` (host or VM):

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
> otherwise interpret `.#vm` as a glob pattern. On the host, swap
> `#vm` → `#host`.

## Adding a tool

Edit `common.nix` (shared) or the profile-specific file (`host.nix` /
`vm.nix`), add to `home.packages`, then `just switch` (or `just
update`).

## Single-shell policy (leaf tools only)

The nix profile carries **leaf CLI tools** plus **editor/AI-agent
runtimes**, and nothing else. Specifically forbidden in `home.packages`
because they would shadow the system toolchain via `PATH` and silently
break builds against the system sysroot/libc/CI: `cc`, `c++`, `gcc`,
`g++`, `clang`, `clang++`, `ld`, `make`, `cmake`, `ninja`, `meson`,
`pkg-config`, `autoconf`, `automake`, `python`, `python3`, `pip`,
`cargo`, `rustc`, `go`. The system `python3` stays the default
interpreter for project builds.

Explicit carve-outs (used only by editor/AI agents, never by the
project build):

- `nodejs` — `node`/`npm`/`npx` for npm-based LSPs and
  copilot-language-server.
- `uv` — `uv`/`uvx` for ad-hoc Python tooling in isolated venvs. `uv`
  does NOT install a `python3` in PATH; it manages its own
  interpreters under `~/.local/share/uv/`. System `python3` is
  untouched.
- `clang-tools` — `clang-format`, `clang-tidy`, `clangd` only (no
  compiler driver).

If a project needs a newer build toolchain, drop a `flake.nix` +
`.envrc` in that project tree (direnv + nix-direnv is already wired
up). Don't add it to `common.nix`/`host.nix`/`vm.nix`.

## Commit signing and SSH auth on the VM (GPG)

The VM uses its own local `gpg-agent`, like the host. Import the work
GPG private key manually on the VM; do not use SSH agent forwarding for
commit signing or SSH auth.

One-time setup on the VM:

```sh
rm -f ~/.ssh/agent.sock ~/.config/git/allowed_signers
gpg --import /path/to/work-private-key.asc
gpg --edit-key 3298945F717C85F8 trust quit
gpg --list-secret-keys --with-keygrip 3298945F717C85F8
```

Add the authentication subkey keygrip to `~/.gnupg/sshcontrol`. The
tracked git config already uses normal OpenPGP signing, so no
`~/.config/git/config.local` override is needed for SSH-format signing.
If `~/.config/git/config.local` only contains the old SSH-format
signing override, remove it too.

Verify on the VM:

```sh
ssh-add -L
git commit --allow-empty -m test
git log --show-signature -1
```

## Caveats

- **GPG / pass**: HM installs `gnupg` and `pass` but does _not_ import
  any private key. On the VM, import the work key manually and add the
  authentication subkey keygrip to `~/.gnupg/sshcontrol`. On the host,
  smartcard access via `pcscd` is configured in `host.nix`
  (`~/.gnupg/scdaemon.conf`).
- **Disk usage**: Nix store + nvim plugins consumes ~3-5 GB. Check
  partition size first on the VM.
- **Network for first nvim launch**: `vim.pack.add` fetches plugins
  from GitHub on first start.
- **Ubuntu apt collisions**: Nix-installed binaries appear first in
  PATH. The leaf-tools policy above exists precisely to keep this
  shadowing contained to harmless tools.

## Podman (rootless, VM only)

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
# cgroupVersion: v1 is fine — only blocks --memory/--cpus flags. The
# podman v5 deprecation warning is silenced by PODMAN_IGNORE_CGROUPSV1_WARNING,
# set in vm.nix.
podman run --rm docker.io/library/alpine echo hi
```

The VM home-manager profile installs `podman`, `crun`, `conmon`,
`netavark`, `aardvark-dns`, `slirp4netns`, and `passt`, and writes
sensible `~/.config/containers/{registries,storage,policy}.conf` files.

## How it's wired

`common.nix` uses `config.lib.file.mkOutOfStoreSymlink` so the symlinks
point at the **live working tree** at `~/.local/share/dotfiles/...`,
not at copies in `/nix/store`. This means:

- Editing `dot_config/nvim/init.lua` in the cloned repo takes effect
  on the next `nvim` launch with no rebuild.
- `home-manager switch` only needs to re-run when adding/removing a
  package or changing what's symlinked.

The zsh plugins (`zsh-syntax-highlighting`, etc.) live in
`$HOME/.nix-profile/share/`. The shared `dot_zshrc` prefers the
nix-profile path on both host and VM, falling back to system paths for
un-bootstrapped states.
