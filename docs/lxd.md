# LXD on Arch

The host package list includes LXD. The system unit list enables `lxd.socket`.
Use `sudo lxc` to manage instances. Do not expose the LXD socket to aibox or
grant agents permanent membership in the `lxd` group. The
[Canonical VM test](canonical-vm.md) permits a separately authorized host
session with temporary LXD access. This access is root-equivalent.

## First Setup

Before starting LXD, complete the AppArmor setup below. Check `/etc/subuid` and
`/etc/subgid` for existing allocations. Native LXD needs subordinate IDs for
root; retain all Podman allocations. On this host, root uses
`1000000-1000999999`, and sommerfeld uses `100000-165535`.

On a new host, only if the root range is free and not yet allocated, run:

```sh
sudo usermod --add-subuids 1000000-1000999999 --add-subgids 1000000-1000999999 root
```

Restart `lxd.service` if it was already running when the allocations changed.

On a new Arch host with Btrfs storage, run:

```sh
just pkg-apply base
just unit-apply
sudo lxd init --preseed < docs/lxd-init.yaml
```

Do not apply the preseed to an existing installation. It selects IPv4 and IPv6
subnets automatically. Check them against LAN and VPN routes before use:

```sh
sudo lxc network show lxdbr0
ip -4 route
ip -6 route
```

## Firewall

Run these commands on the host, outside aibox:

```sh
sudo nft --check --file etc/nftables.conf
just apply
sudo nft --file /etc/nftables.conf
```

The rules permit DNS and DHCP from `lxdbr0`, connections from instances, and
return traffic to instances. Existing ICMP rules permit IPv6 neighbour discovery.
Instances can initiate connections to the LAN and VPN networks as well as the
internet. Unsolicited forwarded connections into the bridge remain blocked.

LXD owns the bridge, address allocation, NAT, and its own firewall table. The repo
replaces only `inet filter`. Do not flush the complete ruleset or restart nftables
with a stop action that flushes LXD's rules.

An IPv6 bridge address does not provide IPv6 internet access without a suitable
host route.

## AppArmor

The package and unit lists include AppArmor. Both kernel command-line templates
enable it alongside the existing security modules. On the host, run:

```sh
just pkg-apply base
just apply
sudo systemctl enable apparmor.service
sudo mkinitcpio -P
```

Do not reboot if image generation fails. If Secure Boot is enabled, ensure the
rebuilt UKIs are signed using the host's existing signing setup before rebooting.
After a successful rebuild, reboot and verify:

```sh
cat /sys/module/apparmor/parameters/enabled
sudo cat /sys/kernel/security/lsm
sudo aa-status
sudo lxc start ubuntu-dev
sudo lxc exec ubuntu-dev -- cat /proc/1/attr/current
```

Skip `lxc start` if the instance is already running. AppArmor must report `Y`,
and the container's process label must show an enforced LXD profile rather than
`unconfined`. If it does not, inspect `journalctl -b -u lxd.service` and kernel
AppArmor messages. Do not disable confinement to bypass a failed start.

## First Container

```sh
sudo lxc launch ubuntu:24.04 ubuntu-dev
sudo lxc exec ubuntu-dev -- cloud-init status --wait
sudo lxc exec ubuntu-dev -- apt-get update
sudo lxc exec ubuntu-dev -- su - ubuntu
```

The container shares the host kernel. Use a VM for kernel and bootloader tests.
The host list includes `cdrtools` for LXD VM support. Pacman supplies LXD's
QEMU and OVMF dependencies.

References: [LXD installation](https://canonical.com/lxd/docs/latest/installing/)
and [firewall configuration](https://canonical.com/lxd/docs/latest/howto/network_bridge_firewalld/).
