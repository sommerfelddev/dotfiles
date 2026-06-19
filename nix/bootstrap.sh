#!/usr/bin/env sh
# Bootstrap a headless dev environment on a fresh Ubuntu 22.04 VM.
# Idempotent: safe to re-run.
#
#   curl -fsSL https://raw.githubusercontent.com/<user>/dotfiles/master/nix/bootstrap.sh | sh
#
# Steps:
#   1. Install Nix (Determinate Systems installer, multi-user).
#   2. Clone (or fast-forward) the dotfiles repo to ~/.local/share/dotfiles.
#   3. Run `home-manager switch --flake .../nix#vm`.
#   4. Initialize VM-role chezmoi config and apply dotfiles.
#   5. Add Nix-store zsh to /etc/shells and chsh the user.
#
# Environment overrides:
#   DOTFILES_REPO   Git URL (default: https://github.com/ruifm/dotfiles)
#   DOTFILES_REF    Branch/tag/sha (default: master)
#   DOTFILES_DIR    Checkout path (default: $HOME/.local/share/dotfiles)

set -eu

REPO="${DOTFILES_REPO:-https://github.com/sommerfelddev/dotfiles}"
REF="${DOTFILES_REF:-master}"
DIR="${DOTFILES_DIR:-$HOME/.local/share/dotfiles}"

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; }

# ── 1. Nix ────────────────────────────────────────────────────────────────────
if ! command -v nix >/dev/null 2>&1; then
  log "Installing Nix (Determinate Systems installer)…"
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix |
    sh -s -- install linux --no-confirm
else
  log "Nix already installed, skipping installer."
fi

# Source nix env for the rest of this script (installer writes
# /etc/profile.d/nix.sh but the current shell hasn't sourced it).
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# ── 2. Repo checkout ─────────────────────────────────────────────────────────
if ! command -v git >/dev/null 2>&1; then
  log "Bootstrapping git via nix profile…"
  nix profile install nixpkgs#git
fi

if [ -d "$DIR/.git" ]; then
  log "Updating existing checkout at $DIR…"
  git -C "$DIR" fetch origin "$REF"
  git -C "$DIR" checkout "$REF"
  git -C "$DIR" pull --ff-only
else
  log "Cloning $REPO ($REF) → $DIR…"
  mkdir -p "$(dirname "$DIR")"
  git clone --branch "$REF" "$REPO" "$DIR"
fi

# ── 3. Home-Manager switch ───────────────────────────────────────────────────
log "Running home-manager switch (this can take a while on first run)…"
nix --extra-experimental-features 'nix-command flakes' \
  run home-manager/master -- \
  switch --impure --flake "$DIR/nix#vm" -b backup

# ── 4. Chezmoi dotfiles ──────────────────────────────────────────────────────
log "Writing VM chezmoi config and applying dotfiles…"
CHEZMOI="$HOME/.nix-profile/bin/chezmoi"
if [ ! -x "$CHEZMOI" ]; then
  CHEZMOI=$(command -v chezmoi)
fi
CHEZMOI_MACHINE_ROLE=vm "$CHEZMOI" init -S "$DIR" --promptDefaults
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml"
if ! grep -Eq '^[[:space:]]*machineRole[[:space:]]*=[[:space:]]*"vm"[[:space:]]*$' "$CONFIG"; then
  err "$CONFIG does not set machineRole = \"vm\""
  exit 1
fi
"$CHEZMOI" apply -S "$DIR" -v

log "Restarting GnuPG through the Nix profile…"
GPGCONF="$HOME/.nix-profile/bin/gpgconf"
GPG_CONNECT_AGENT="$HOME/.nix-profile/bin/gpg-connect-agent"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user stop \
    gpg-agent.service \
    gpg-agent.socket \
    gpg-agent-ssh.socket \
    gpg-agent-extra.socket \
    gpg-agent-browser.socket >/dev/null 2>&1 || true
  systemctl --user mask \
    gpg-agent.socket \
    gpg-agent-ssh.socket \
    gpg-agent-extra.socket \
    gpg-agent-browser.socket >/dev/null 2>&1 || true
fi
"$GPGCONF" --kill all >/dev/null 2>&1 || true
"$GPGCONF" --launch gpg-agent
"$GPG_CONNECT_AGENT" 'getinfo version' /bye

# ── 5. chsh to nix-store zsh ─────────────────────────────────────────────────
NIX_ZSH="$HOME/.nix-profile/bin/zsh"
if [ -x "$NIX_ZSH" ]; then
  if ! grep -qxF "$NIX_ZSH" /etc/shells 2>/dev/null; then
    log "Appending $NIX_ZSH to /etc/shells (requires sudo)…"
    echo "$NIX_ZSH" | sudo tee -a /etc/shells >/dev/null
  fi
  current_shell="$(getent passwd "$USER" | cut -d: -f7)"
  if [ "$current_shell" != "$NIX_ZSH" ]; then
    log "Changing login shell to $NIX_ZSH (requires sudo)…"
    sudo chsh -s "$NIX_ZSH" "$USER"
  fi
fi

log "Done. Log out and back in for the new shell to take effect."
log "Then run 'nvim' once to let it fetch plugins on first launch."
