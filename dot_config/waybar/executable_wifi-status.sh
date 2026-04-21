#!/bin/sh
# Emit waybar JSON describing wifi link state. Handles bond-slaved wlan
# interfaces where waybar's built-in network module fails to detect wifi.
set -eu

iface=wlan0
link=$(iw dev "$iface" link 2>/dev/null || true)

if [ -z "$link" ] || [ "$link" = "Not connected." ]; then
  printf '{"text":"wifi off","class":"down"}\n'
  exit 0
fi

ssid=$(printf '%s\n' "$link" | awk -F': ' '/^\tSSID:/{print $2; exit}')
dbm=$(printf '%s\n' "$link" | awk '/signal:/{print $2; exit}')
pct=$(awk -v r="${dbm:-0}" 'BEGIN{p=2*(r+100); if(p>100)p=100; if(p<0)p=0; printf "%d",p}')

printf '{"text":"%s %s%%","class":"up","tooltip":"%s · %s dBm"}\n' \
  "$ssid" "$pct" "$iface" "$dbm"
