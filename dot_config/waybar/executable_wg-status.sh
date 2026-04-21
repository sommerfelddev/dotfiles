#!/bin/sh
# Emit waybar JSON describing wireguard status. Uses `ip` (no root needed).
set -eu

iface=$(ip -br link show type wireguard 2>/dev/null | awk 'NF{print $1; exit}')

if [ -n "${iface:-}" ]; then
  printf '{"text":"WG %s","class":"up","tooltip":"%s"}\n' \
    "$iface" \
    "$(ip -br -4 addr show dev "$iface" 2>/dev/null | awk '{for(i=3;i<=NF;i++)printf "%s ",$i}')"
else
  printf '{"text":"WG off","class":"down","tooltip":"no wireguard interface"}\n'
fi
