#!/bin/sh
# Print 0–100 to wob's fifo to flash a volume bar overlay.
# Usage: vol-osd.sh up|down|mute (mute toggles)
set -eu

fifo=${XDG_RUNTIME_DIR:-/tmp}/wob.sock
sink='@DEFAULT_SINK@'

case "${1:-}" in
  up) pactl set-sink-volume "$sink" +5% ;;
  down) pactl set-sink-volume "$sink" -5% ;;
  mute) pactl set-sink-mute "$sink" toggle ;;
  *)
    echo "usage: $0 up|down|mute" >&2
    exit 2
    ;;
esac

muted=$(pactl get-sink-mute "$sink" | awk '{print $2}')
if [ "$muted" = "yes" ]; then
  printf '0\n' >"$fifo"
else
  pactl get-sink-volume "$sink" |
    awk '/Volume:/ { for (i=1;i<=NF;i++) if ($i ~ /%/) { gsub(/%/,"",$i); print $i; exit } }' \
      >"$fifo"
fi
