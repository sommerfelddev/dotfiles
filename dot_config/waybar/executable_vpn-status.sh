#!/bin/sh
# Waybar custom/vpn module: report whether the wireguard interface
# (managed by systemd-networkd) is admin-up. Output is a single line of
# JSON so waybar can style it via the .up / .down classes.

iface=hodor

if ip link show "$iface" 2>/dev/null | grep -qE '<[^>]*\<UP\>'; then
  printf '{"text":"VPN","class":"up","tooltip":"%s up"}\n' "$iface"
else
  printf '{"text":"VPN","class":"down","tooltip":"%s down"}\n' "$iface"
fi
