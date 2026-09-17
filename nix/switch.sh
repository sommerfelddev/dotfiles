#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
source "$root/just-lib.sh"
profile=$(_machine_role)
if ! command -v nix >/dev/null 2>&1; then
  [[ $profile != canonical ]] || {
    echo 'Install upstream Nix first.' >&2
    exit 1
  }
  echo 'Nix is not installed; skipping Home-Manager.' >&2
  exit 0
fi
if [[ -n ${1:-} && $profile != "$1" ]]; then
  echo "error: expected role $1, got $profile" >&2
  exit 1
fi
export USER="${USER:-$(id -un)}"
export HOME="${HOME:?HOME must be set}"
generation=$(sh "$root/nix/with-github-auth.sh" \
  nix --extra-experimental-features 'nix-command flakes' build --impure \
  --no-link --print-out-paths "$root/nix#homeConfigurations.$profile.activationPackage")
HOME_MANAGER_BACKUP_EXT=backup "$generation/activate"
if [[ $profile != canonical ]]; then
  shell="$HOME/.nix-profile/bin/zsh"
  if ! grep -qxF "$shell" /etc/shells; then
    printf '%s\n' "$shell" | sudo tee -a /etc/shells >/dev/null
  fi
  if [[ $(getent passwd "$USER" | cut -d: -f7) != "$shell" ]]; then
    sudo chsh -s "$shell" "$USER"
  fi
fi
