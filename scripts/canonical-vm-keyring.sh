#!/bin/bash
set -euo pipefail
test "$(id -u)" = 0
test -f /etc/canonical-lab
systemd-detect-virt --vm --quiet
home=/home/canonical-test
key=$home/.local/state/canonical-lab/keyring-password
test ! -f "$key" || exit 0
systemctl stop gdm
loginctl terminate-user canonical-test
umask 077
install -d -o canonical-test -g canonical-test "$home/.local/state/canonical-lab"
if test -d "$home/.local/share/keyrings"; then
  test ! -e "$home/.local/share/keyrings-before-lab-unlock"
  mv "$home/.local/share/keyrings" "$home/.local/share/keyrings-before-lab-unlock"
fi
cat >"$key"
test -s "$key"
chown canonical-test:canonical-test "$key"
dropin=$home/.config/systemd/user/gnome-keyring-daemon.service.d
install -d -o canonical-test -g canonical-test "$dropin"
cat >"$dropin/lab.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/gnome-keyring-daemon --foreground --components=pkcs11,secrets --control-directory=%t/keyring --unlock
StandardInput=file:%h/.local/state/canonical-lab/keyring-password
EOF
chown canonical-test:canonical-test "$dropin/lab.conf"
