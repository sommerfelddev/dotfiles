#!/bin/sh
# Print brightness percent to wob's fifo to flash a brightness bar.
# Usage: brightness-osd.sh up|down
set -eu

fifo=${XDG_RUNTIME_DIR:-/tmp}/wob.sock

case "${1:-}" in
  up) brightnessctl set +5% >/dev/null ;;
  down) brightnessctl set 5%- >/dev/null ;;
  *)
    echo "usage: $0 up|down" >&2
    exit 2
    ;;
esac

cur=$(brightnessctl g)
max=$(brightnessctl m)
printf '%d\n' "$((cur * 100 / max))" >"$fifo"
