#!/usr/bin/env dash
# Toggle wifi (wlan0) Powered state via iwd's D-Bus API. Driven by waybar
# on-click on the custom/wifi module.
set -eu

iface=wlan0
svc=net.connman.iwd

device=$(busctl --system --json=short call "$svc" / \
  org.freedesktop.DBus.ObjectManager GetManagedObjects |
  jq -r --arg iface "$iface" '
      (.data[0] // .data) as $objs
      | $objs | to_entries[]
      | select(.value["net.connman.iwd.Device"].Name.data == $iface)
      | .key')

[ -n "$device" ] || {
  notify-send -u critical "wifi" "iwd device $iface not found"
  exit 1
}

powered=$(busctl --system --json=short get-property "$svc" "$device" \
  net.connman.iwd.Device Powered | jq -r '.data')

if [ "$powered" = "true" ]; then
  busctl --system set-property "$svc" "$device" net.connman.iwd.Device Powered b false
else
  busctl --system set-property "$svc" "$device" net.connman.iwd.Device Powered b true
fi
