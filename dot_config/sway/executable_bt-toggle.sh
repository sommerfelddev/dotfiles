#!/bin/sh
# Toggle Bluetooth power via bluetoothctl. Uses notify-send's synchronous
# hint so repeated toggles replace the previous notification instead of
# stacking.
set -eu

state=$(bluetoothctl show | awk '/Powered:/ {print $2}')
if [ "$state" = "yes" ]; then
  bluetoothctl power off >/dev/null
  notify-send -t 1500 -h string:x-canonical-private-synchronous:bt \
    'Bluetooth' 'off'
else
  bluetoothctl power on >/dev/null
  notify-send -t 1500 -h string:x-canonical-private-synchronous:bt \
    'Bluetooth' 'on'
fi
