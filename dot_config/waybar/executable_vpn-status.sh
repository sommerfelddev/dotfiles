#!/bin/sh
# Waybar custom/vpn module: report whether the wireguard interface
# (managed by systemd-networkd) is admin-up. Pango markup makes the
# state visually unambiguous (green shield up, red strikethrough down)
# even before CSS classes are taken into account.

iface=hodor

if ip link show "$iface" 2>/dev/null | grep -qE '<[^>]*\<UP\>'; then
  printf '{"text":"<span color=\\"#b8bb26\\">󰒃 VPN</span>","class":"up","tooltip":"%s up — click to disconnect"}\n' "$iface"
else
  printf '{"text":"<span color=\\"#928374\\"><s>󰒃 VPN</s></span>","class":"down","tooltip":"%s down — click to connect"}\n' "$iface"
fi
