#!/bin/bash
set -euo pipefail
systemd-detect-virt --vm --quiet
test -f /cdrom/lab/owner

mount_config() {
  mkdir -p "$1"
  modprobe 9pnet_virtio
  mount -t 9p config "$1" -o access=0,trans=virtio ||
    mount -t virtiofs config "$1"
}

if [ "${1:-}" = live ]; then
  mount_config /mnt/lxd-agent
  (cd /mnt/lxd-agent && ./install.sh)
  umount /mnt/lxd-agent
  systemctl start lxd-agent
  exit 0
fi

test -d /target/etc
install -m 600 /cdrom/lab/owner /target/etc/canonical-lab
install -m 600 /cdrom/lab/disk-password /target/root/lab-unlock.key
# The disposable guest stores its unlock key in the unencrypted initramfs.
awk 'NF && $1 !~ /^#/ {$3="/root/lab-unlock.key"} {print}' \
  /target/etc/crypttab >/target/etc/crypttab.lab
mv /target/etc/crypttab.lab /target/etc/crypttab
mkdir -p /target/etc/dracut.conf.d
printf 'install_items+=" /root/lab-unlock.key "\n' >/target/etc/dracut.conf.d/99-canonical-lab.conf
printf 'canonical-test ALL=(ALL:ALL) NOPASSWD:ALL\n' >/target/etc/sudoers.d/canonical-lab
chmod 440 /target/etc/sudoers.d/canonical-lab
printf '[daemon]\nAutomaticLoginEnable=True\nAutomaticLogin=canonical-test\n' >/target/etc/gdm3/custom.conf
printf 'PermitRootLogin no\nPasswordAuthentication no\nAllowAgentForwarding no\n' >/target/etc/ssh/sshd_config.d/00-canonical-lab.conf
printf 'APT::Get::Assume-Yes "true";\n' >/target/etc/apt/apt.conf.d/99canonical-lab
mkdir -p /target/etc/dconf/profile /target/etc/dconf/db/canonical-lab.d/locks
if ! test -f /target/etc/dconf/profile/user; then
  printf 'user-db:user\n' >/target/etc/dconf/profile/user
fi
printf 'system-db:canonical-lab\n' >>/target/etc/dconf/profile/user
printf '[org/gnome/desktop/interface]\nclock-show-weekday=false\n' >/target/etc/dconf/db/canonical-lab.d/00-settings
printf '/org/gnome/desktop/interface/clock-show-weekday\n' >/target/etc/dconf/db/canonical-lab.d/locks/test
curtin in-target --target=/target -- dconf update

mount_config /target/mnt/lxd-agent
curtin in-target --target=/target -- bash -c 'cd /mnt/lxd-agent && ./install.sh'
umount /target/mnt/lxd-agent
curtin in-target --target=/target -- update-initramfs -u -k all
# shellcheck disable=SC2016
curtin in-target --target=/target -- bash -ec \
  'for image in /boot/initrd.img-*; do lsinitrd "$image" | grep -F root/lab-unlock.key; done'
