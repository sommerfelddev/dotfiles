#!/bin/sh
# Emit waybar JSON describing wifi link state. Uses iwctl (from iwd) so we
# don't need the separate `iw` package. Handles bond-slaved wlan where
# waybar's built-in network module fails to detect wifi.
set -eu

iface=wlan0

# iwctl emits ANSI colour codes even when stdout is a pipe; strip them.
out=$(iwctl station "$iface" show 2>/dev/null | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' || true)

state=$(printf '%s\n' "$out" | awk '/ State / {print $NF; exit}')
if [ "$state" != "connected" ]; then
  printf '{"text":"wifi off","class":"down"}\n'
  exit 0
fi

ssid=$(printf '%s\n' "$out" |
  sed -n 's/^[[:space:]]*Connected network[[:space:]]\{2,\}//p' |
  sed 's/[[:space:]]*$//')
rssi=$(printf '%s\n' "$out" |
  sed -n 's/^[[:space:]]*\*\{0,1\}[[:space:]]*AverageRSSI[[:space:]]\{2,\}//p' |
  awk '{print $1; exit}')
pct=$(awk -v r="${rssi:-0}" 'BEGIN{p=2*(r+100); if(p>100)p=100; if(p<0)p=0; printf "%d",p}')

printf '{"text":"%s %s%%","class":"up","tooltip":"%s · %s dBm"}\n' \
  "$ssid" "$pct" "$iface" "$rssi"
