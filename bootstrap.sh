#!/bin/sh
# bootstrap.sh — take a fresh minimal Arch install (only the 'base'
# meta-package installed) to the point where `just init` has run, the
# dotfiles are deployed, and recommended services are enabled.
#
# Prerequisites (from the Arch installation guide):
#   - A regular user already exists and is a member of the 'wheel' group.
#   - You are logged in as that user.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/sommerfelddev/dotfiles/master/bootstrap.sh | sh
#
# Overrides:
#   DOTFILES_REPO  (default: https://github.com/sommerfelddev/dotfiles.git)
#   DOTFILES_DIR   (default: $HOME/dotfiles)

set -eu

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31m==>\033[0m %s\n' "$*" >&2
  exit 1
}

# 0. refuse root — Home Manager and the user-owned dotfiles expect a real user.
[ "$(id -u)" -ne 0 ] || die "run this as your regular user, not root"

# 1. user must be in wheel (required so the sudoers rule we enable takes effect)
id -nG "$USER" | tr ' ' '\n' | grep -qx wheel ||
  die "user '$USER' must be in the 'wheel' group"

# 2. install sudo + pacman prerequisites, enable wheel in sudoers.
#    `chezmoi` is intentionally NOT in this list — it lands in
#    ~/.nix-profile/bin after the first nix-switch. `just` and `git` stay
#    on pacman so the script + early `just nix-switch` work before the nix
#    profile is activated.
PREREQS='sudo git just efibootmgr nix'
SUDOERS_SED='s/^# *\(%wheel ALL=(ALL:ALL\(:ALL\)*) ALL\)/\1/'

if ! command -v sudo >/dev/null 2>&1; then
  log 'installing prerequisites (prompting for root password)'
  su -c "pacman -Syu --needed --noconfirm ${PREREQS} && \
           sed -i '${SUDOERS_SED}' /etc/sudoers"
else
  log 'installing prerequisites'
  # shellcheck disable=SC2086  # PREREQS is an intentional word list
  sudo pacman -Syu --needed --noconfirm ${PREREQS}
  sudo sed -i "${SUDOERS_SED}" /etc/sudoers
fi

# 3. enable the nix daemon (multi-user mode; pacman ships the unit)
log 'enabling nix-daemon'
sudo systemctl enable --now nix-daemon.socket

# Source the nix profile so `nix` is on PATH for the rest of this
# script (pacman drops /etc/profile.d/nix.sh but the current shell
# didn't read it).
for f in /etc/profile.d/nix.sh /etc/profile.d/nix-daemon.sh; do
  if [ -r "$f" ]; then
    # shellcheck disable=SC1090
    . "$f"
    break
  fi
done

# 4. provision subuid/subgid for rootless podman (nix-installed podman
#    relies on the system shadow-utils ranges; idempotent — only acts
#    when no range exists for the current user).
if ! grep -q "^$USER:" /etc/subuid; then
  log "provisioning /etc/subuid + /etc/subgid for rootless containers"
  sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
fi

# 5. clone dotfiles
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
REPO_URL="${DOTFILES_REPO:-https://github.com/sommerfelddev/dotfiles.git}"
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  log "cloning $REPO_URL -> $DOTFILES_DIR"
  git clone "$REPO_URL" "$DOTFILES_DIR"
else
  log "using existing clone at $DOTFILES_DIR"
fi
cd "$DOTFILES_DIR"

# 6. nix-switch FIRST. This installs chezmoi (plus the wayland session
#    tools, qrencode, torsocks, lshw, yt-dlp, streamlink, tesseract,
#    whisper-cpp, …) into ~/.nix-profile/bin so the subsequent `just init`
#    finds them on PATH. The repo is already a valid Nix flake — we don't
#    need chezmoi to have run yet.
log 'running nix-switch (installs chezmoi + user-leaf tools from nix)'
just nix-switch

# Add nix-profile to PATH for the remaining steps so freshly installed
# tools (chezmoi, etc.) are picked up immediately. Login shells will
# resolve it via /etc/profile.d/hm-session-vars.sh after re-login.
export PATH="$HOME/.nix-profile/bin:$PATH"

# 7. run just init — this deploys chezmoi, installs the 'base' meta list
#    (which pulls in sudo-rs via pacman), deploys
#    /etc/sudoers-rs, /etc/pam.d/sudo, creates user-scoped
#    ~/.local/bin/{sudo,su,visudo,sudoedit} symlinks pointing at sudo-rs,
#    and installs git hooks. The classic 'sudo' package is only a bootstrap
#    helper and may be removed if it shows up as undeclared. `just init`
#    also re-runs nix-switch as its last step (a no-op since step 6 already
#    activated the profile).
log 'running just init'
just init

# 8. refresh pacman mirrorlist once via reflector (config deployed by chezmoi)
log 'refreshing pacman mirrorlist via reflector'
sudo reflector @/etc/xdg/reflector/reflector.conf \
  --save /etc/pacman.d/mirrorlist ||
  warn 'reflector failed; keeping existing mirrorlist'

# 9. create XDG user directories (~/Documents, ~/Downloads, etc.)
if command -v xdg-user-dirs-update >/dev/null 2>&1; then
  log 'creating XDG user directories'
  xdg-user-dirs-update || warn 'xdg-user-dirs-update failed'
fi

# 10. optional: create an Arch EFI boot entry if none exists
if [ -d /sys/firmware/efi ]; then
  if ! sudo efibootmgr 2>/dev/null | grep -iq arch; then
    warn 'no Arch Linux EFI boot entry found'
    warn 'after first kernel install, run: sudo mkinitcpio -P'
    warn 'then register the UKIs with efibootmgr (hardened first so it'\''s the default):'
    # shellcheck disable=SC1003 # backslash is literal text shown to the user
    warn '  sudo efibootmgr --create --disk /dev/nvme0n1 --part 1 \'
    warn "      --label 'Arch Hardened' --loader '\\EFI\\Linux\\arch-linux-hardened.efi'"
    # shellcheck disable=SC1003
    warn '  sudo efibootmgr --create --disk /dev/nvme0n1 --part 1 \'
    warn "      --label 'Arch Hardened Fallback' --loader '\\EFI\\Linux\\arch-linux-hardened-fallback.efi'"
    warn 'and the linux-lts fallback kernel UKIs:'
    # shellcheck disable=SC1003
    warn '  sudo efibootmgr --create --disk /dev/nvme0n1 --part 1 \'
    warn "      --label 'Arch LTS' --loader '\\EFI\\Linux\\arch-linux-lts.efi'"
    # shellcheck disable=SC1003
    warn '  sudo efibootmgr --create --disk /dev/nvme0n1 --part 1 \'
    warn "      --label 'Arch LTS Fallback' --loader '\\EFI\\Linux\\arch-linux-lts-fallback.efi'"
  fi
fi

log 'done. Log out and back in (or reboot) to pick up shell and group changes.'
