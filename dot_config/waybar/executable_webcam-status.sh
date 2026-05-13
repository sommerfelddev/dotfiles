#!/bin/sh
# Emit waybar JSON when any /dev/video* device is held open by a process.
# V4L2 capture (firefox, zoom, OBS, etc.) doesn't go through PipeWire's
# privacy portal, so the built-in waybar privacy module never sees it.
set -eu

devs=$(echo /dev/video[0-9]*)
case "$devs" in
  '/dev/video[0-9]*') exit 0 ;;  # no devices present
esac

# fuser exits 0 when at least one device has an opener, 1 otherwise. Stderr
# carries 'PID' for each match; redirect it away.
if fuser $devs >/dev/null 2>&1; then
  printf '{"text":"CAM","tooltip":"webcam in use","class":"active","alt":"active"}\n'
else
  printf '{"text":"","alt":"idle"}\n'
fi
