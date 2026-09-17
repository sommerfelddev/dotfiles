#!/usr/bin/env bash
set -euo pipefail
if [[ -e /nix/nix-installer || -e /etc/nix/nix.custom.conf ]] || dpkg-query -W nix-bin >/dev/null 2>&1; then
  echo 'error: this recipe is only for the upstream multi-user installer' >&2
  exit 1
fi
nix=/nix/var/nix/profiles/default/bin/nix
[[ -x $nix ]]
sudo "$nix" --extra-experimental-features nix-command upgrade-nix --profile /nix/var/nix/profiles/default
sudo systemctl daemon-reload
sudo systemctl restart nix-daemon.service
"$nix" --version
