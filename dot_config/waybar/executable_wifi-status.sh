#!/bin/sh
# Emit waybar JSON describing wifi link state.
#
# Uses iwd's D-Bus API for state + SSID (net.connman.iwd is a documented,
# stable interface) and /proc/net/wireless for signal strength. No reliance
# on iwctl's human-readable TTY output.
set -eu

iface=wlan0
svc=net.connman.iwd

down() {
	printf '{"text":"wifi off","class":"down"}\n'
	exit 0
}

# Locate the iwd object path for this interface.
station=$(busctl --system --json=short call "$svc" / \
	org.freedesktop.DBus.ObjectManager GetManagedObjects 2>/dev/null |
	jq -r --arg iface "$iface" '
      (.data[0] // .data) as $objs
      | $objs | to_entries[]
      | select(.value["net.connman.iwd.Device"].Name.data == $iface)
      | .key' 2>/dev/null || true)
[ -n "$station" ] || down

state=$(busctl --system --json=short get-property "$svc" "$station" \
	net.connman.iwd.Station State 2>/dev/null | jq -r '.data' 2>/dev/null || true)
[ "$state" = "connected" ] || down

netpath=$(busctl --system --json=short get-property "$svc" "$station" \
	net.connman.iwd.Station ConnectedNetwork | jq -r '.data')
ssid=$(busctl --system --json=short get-property "$svc" "$netpath" \
	net.connman.iwd.Network Name | jq -r '.data')

# /proc/net/wireless: "<iface>: <status> <qual>. <level>. <noise>. ..."
# We want <level> (column 4), which is dBm. Strip trailing dot.
rssi=$(awk -v i="$iface:" '$1==i { sub(/\./, "", $4); print $4; exit }' /proc/net/wireless)
rssi=${rssi:-0}

pct=$(awk -v r="$rssi" 'BEGIN{p=2*(r+100); if(p>100)p=100; if(p<0)p=0; printf "%d",p}')
color=$(awk -v p="$pct" 'BEGIN{
	if (p < 20) print "#fb4934"
	else if (p < 40) print "#fe8019"
	else if (p < 70) print "#fabd2f"
	else print "#b8bb26"
}')

printf '{"text":"%s <span color=\x27%s\x27>%s%%</span>","class":"up","tooltip":"%s · %s dBm"}\n' \
	"$ssid" "$color" "$pct" "$iface" "$rssi"
