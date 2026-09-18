#!/bin/bash
set -euo pipefail
test -f /etc/canonical-lab
test "$(id -un)" = canonical-test
# shellcheck source=/dev/null
test "$(
  . /etc/os-release
  printf '%s' "$ID"
)" = ubuntu
systemd-detect-virt --vm --quiet
cd "$HOME/dotfiles"

check_extensions() {
  test "$(/usr/bin/gsettings get org.gnome.shell disable-user-extensions)" = false
  while IFS= read -r extension; do
    gnome-extensions info "$extension"
    gnome-extensions list --enabled | grep -Fx "$extension"
    gnome-extensions info "$extension" | grep -Eq 'State: (ACTIVE|ENABLED)$'
  done < <(sed '/^#/d; /^$/d' meta/canonical/extensions.txt)
}

check_mattermost_keyring() {
  systemctl is-active dotfiles-mattermost-keyring.path
  snap run --shell mattermost-desktop <<'EOF'
dbus-send --session --print-reply --dest=org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.DBus.Peer.Ping
EOF
  grep 'Secure storage initialized' "$HOME/snap/mattermost-desktop/current/.config/Mattermost/logs/main.log" |
    tail -n 1 | grep -F 'encryption available'
}

case "${1:?stage required}" in
  session)
    check_extensions
    test "$(secret-tool lookup application canonical-lab)" = lab-value
    check_mattermost_keyring
    ;;
  nix)
    if ! test -x /nix/var/nix/profiles/default/bin/nix; then
      curl --fail --location https://nixos.org/nix/install -o /tmp/install-nix
      sh /tmp/install-nix --daemon --yes --no-channel-add
    fi
    ;;
  identity)
    install -d -m 700 "$HOME/.gnupg" "$HOME/.config/chezmoi"
    if ! gpg --list-secret-keys canonical-test@example.invalid >/dev/null 2>&1; then
      gpg --batch --pinentry-mode loopback --passphrase '' --quick-generate-key \
        'Canonical Test <canonical-test@example.invalid>' ed25519 sign 1y
    fi
    fingerprint=$(gpg --with-colons --list-secret-keys canonical-test@example.invalid | awk -F: '$1=="fpr" {print $10; exit}')
    cat >"$HOME/.config/chezmoi/chezmoi.toml" <<EOF
sourceDir = "$HOME/dotfiles"
[data]
machineRole = "canonical"
workName = "Canonical Test"
workEmail = "canonical-test@example.invalid"
workSigningKey = "$fingerprint"
EOF
    git init -q
    git -c user.name='Canonical Test' -c user.email=canonical-test@example.invalid \
      -c commit.gpgsign=false add .
    git -c core.hooksPath=/dev/null -c user.name='Canonical Test' -c user.email=canonical-test@example.invalid \
      -c commit.gpgsign=false commit --allow-empty -qm 'Import lab source'
    ;;
  setup)
    export NIX_CONFIG='experimental-features = nix-command flakes'
    export PATH="/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:$PATH"
    nix develop ./nix --command just canonical-setup
    ;;
  settings)
    export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
    just canonical-desktop-restore
    just canonical-desktop
    test "$(gsettings get org.gnome.desktop.interface clock-show-weekday)" = false
    ;;
  check)
    export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
    test -n "${WAYLAND_DISPLAY:-}"
    test "${XDG_CURRENT_DESKTOP#*GNOME}" != "$XDG_CURRENT_DESKTOP"
    just canonical-desktop
    test "$(gsettings writable org.gnome.desktop.interface clock-show-weekday)" = false
    test "$(gsettings get org.gnome.desktop.interface clock-show-weekday)" = false
    just canonical-lab-check
    just apply
    # shellcheck disable=SC2016
    "$HOME/.nix-profile/bin/zsh" -lc 'test -x "$NVIM_TREESITTER_CC"'
    lsblk -sno TYPE "$(findmnt -no SOURCE /)" | grep -Fx crypt
    gpg --batch --local-user canonical-test@example.invalid --output /tmp/lab-signature --detach-sign --yes README.md
    gpg --verify /tmp/lab-signature README.md
    podman run --rm docker.io/library/alpine:3.22 true
    # shellcheck disable=SC2016
    aibox -- sh -c 'test "$AIBOX" = 1 && test ! -S /var/lib/lxd/unix.socket'
    check_extensions
    busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login \
      org.freedesktop.Secret.Collection Locked | grep -Fx 'b false'
    printf 'lab-value' | timeout 30 secret-tool store --label='Canonical lab test' application canonical-lab
    test "$(secret-tool lookup application canonical-lab)" = lab-value
    check_mattermost_keyring
    notify-send 'Canonical lab' 'Notification test'
    ;;
  *) exit 2 ;;
esac
