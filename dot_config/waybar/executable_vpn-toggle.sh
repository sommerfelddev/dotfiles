#!/bin/sh
# Toggle the wireguard interface managed by systemd-networkd. Polkit
# rule (etc/polkit-1/rules.d/50-networkd-wheel.rules) lets wheel-group
# members invoke networkctl up/down without a password prompt.
#
# After the state change, send SIGRTMIN+8 to waybar so the custom/vpn
# module refreshes immediately instead of waiting for the next interval.

set -eu

iface=hodor

if ip link show "$iface" 2>/dev/null | grep -qE '<[^>]*\<UP\>'; then
  networkctl down "$iface"
else
  networkctl up "$iface"
fi

# Refresh waybar's custom/vpn module right away.
pid=$(pidof waybar || true)
if [ -n "$pid" ]; then kill -SIGRTMIN+8 "$pid" 2>/dev/null || true; fi
