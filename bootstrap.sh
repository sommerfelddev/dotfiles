#!/bin/sh
# bootstrap.sh — take a fresh minimal Arch install (only the 'base'
# meta-package installed) to the point where `just init` has run and
# the dotfiles are deployed.
#
# Must be executed as the regular (non-root) user that will own the
# system. paru and makepkg refuse to run as root, so we keep everything
# user-side and only escalate for the pacman + sudoers step.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/sommerfelddev/dotfiles/master/bootstrap.sh | sh
#
# Overrides:
#   DOTFILES_REPO  (default: https://github.com/sommerfelddev/dotfiles.git)
#   DOTFILES_DIR   (default: $HOME/dotfiles)

set -eu

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

# 0. refuse root — paru/makepkg won't run as root
[ "$(id -u)" -ne 0 ] || die "run this as your regular user, not root"

# 1. user must be in wheel (required so the sudoers rule we enable takes effect)
id -nG "$USER" | tr ' ' '\n' | grep -qx wheel \
    || die "user '$USER' must be in the 'wheel' group"

# 2. install sudo + pacman prerequisites, enable wheel in sudoers.
#    If sudo is absent we do this in a single su -c so the root password
#    is entered only once. If sudo is already there, reuse it.
PREREQS='sudo git base-devel chezmoi just efibootmgr'
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

# 3. bootstrap paru-bin from AUR if missing
if ! command -v paru >/dev/null 2>&1; then
    log 'building paru-bin from AUR'
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
    (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
fi

# 4. clone dotfiles
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
REPO_URL="${DOTFILES_REPO:-https://github.com/sommerfelddev/dotfiles.git}"
if [ ! -d "$DOTFILES_DIR/.git" ]; then
    log "cloning $REPO_URL -> $DOTFILES_DIR"
    git clone "$REPO_URL" "$DOTFILES_DIR"
else
    log "using existing clone at $DOTFILES_DIR"
fi

# 5. run just init — this deploys chezmoi, installs the 'base' meta list
#    (swapping sudo for doas-sudo-shim via paru -S --ask=4), deploys
#    /etc/doas.conf, and installs git hooks.
cd "$DOTFILES_DIR"
log 'running just init'
just init

# 6. optional: create an Arch EFI boot entry if none exists
if [ -d /sys/firmware/efi ]; then
    if ! sudo efibootmgr 2>/dev/null | grep -iq arch; then
        log 'no Arch Linux EFI boot entry found; launching create-efi'
        "$HOME/.local/bin/create-efi"
    fi
fi

log 'done. Log out and back in (or reboot) to pick up shell and group changes.'
