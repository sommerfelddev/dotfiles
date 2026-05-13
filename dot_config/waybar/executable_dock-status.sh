#!/bin/sh
# Detect a Lenovo ThinkPad USB-C Dock Gen2 by its distinctive built-in
# ethernet adapter (17ef:a387). The dock's USB hubs share product IDs
# with internal ThinkPad hubs on some models, but the ethernet is only
# present when the dock is physically attached.
#
# Output is a single waybar JSON record. When undocked, "text" is empty
# so waybar collapses the module — no clutter on the bar when on the go.

set -eu

docked=0
for dev in /sys/bus/usb/devices/*/; do
  [ -f "$dev/idVendor" ] && [ -f "$dev/idProduct" ] || continue
  v=$(cat "$dev/idVendor")
  p=$(cat "$dev/idProduct")
  if [ "$v" = "17ef" ] && [ "$p" = "a387" ]; then
    docked=1
    break
  fi
done

if [ "$docked" -eq 1 ]; then
  printf '{"text":"󰓁","tooltip":"Docked: ThinkPad USB-C Dock Gen2","class":"docked","alt":"docked"}\n'
else
  printf '{"text":"","tooltip":"Undocked","class":"undocked","alt":"undocked"}\n'
fi
