#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source just-lib.sh
[[ $(_machine_role) == canonical ]]
[[ $(
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "$ID"
) == ubuntu ]]
# Parse before replacing the installed profile.
sudo apparmor_parser --skip-kernel-load --skip-cache canonical/apparmor/dotfiles-nix
sudo install -m 644 canonical/apparmor/dotfiles-nix /etc/apparmor.d/dotfiles-nix
sudo apparmor_parser --replace /etc/apparmor.d/dotfiles-nix
sudo snap connect thunderbird:gpg-keys
sudo install -D -m 644 scripts/mattermost_keyring.py /usr/local/lib/dotfiles/mattermost_keyring.py
sudo install -m 644 canonical/systemd/dotfiles-mattermost-keyring.{service,path} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now dotfiles-mattermost-keyring.path dotfiles-mattermost-keyring.service
systemctl --user daemon-reload
systemctl --user enable --now gpg-agent.socket gpg-agent-ssh.socket podman.socket
echo 'Existing GPG agent processes keep their executable until the next login.'
