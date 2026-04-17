#!/bin/sh
# Cycle display mode: mirror → laptop-off → side-by-side
# Usage: display-toggle.sh [init]
# Bound to F7 in sway config; also runs at startup with "init"

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/display-mode"
MIRROR_PID="${XDG_RUNTIME_DIR:-/tmp}/wl-mirror.pid"

LAPTOP=$(swaymsg -t get_outputs -r | jq -r '.[] | select(.name | test("eDP")) | .name')
EXTERNAL=$(swaymsg -t get_outputs -r | jq -r '[.[] | select(.name | test("eDP") | not) | .name] | first // empty')

if [ -z "$EXTERNAL" ]; then
    [ -z "$1" ] && notify-send "Display" "No external display connected"
    exit 0
fi

# Stop any running wl-mirror
if [ -f "$MIRROR_PID" ]; then
    kill "$(cat "$MIRROR_PID")" 2>/dev/null
    rm -f "$MIRROR_PID"
fi

LAPTOP_WIDTH=$(swaymsg -t get_outputs -r | jq -r ".[] | select(.name == \"$LAPTOP\") | .current_mode.width")
[ -z "$LAPTOP_WIDTH" ] && LAPTOP_WIDTH=1920

# On init, go straight to laptop-off; otherwise cycle
if [ "$1" = "init" ]; then
    NEXT="laptop-off"
else
    CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "laptop-off")
    case "$CURRENT" in
        laptop-off) NEXT="side-by-side" ;;
        side-by-side) NEXT="mirror" ;;
        *) NEXT="laptop-off" ;;
    esac
fi

case "$NEXT" in
    mirror)
        swaymsg output "$LAPTOP" enable
        swaymsg output "$EXTERNAL" enable
        swaymsg focus output "$EXTERNAL"
        wl-mirror "$LAPTOP" &
        echo $! > "$MIRROR_PID"
        sleep 0.3
        swaymsg focus output "$LAPTOP"
        echo "mirror" > "$STATE_FILE"
        [ -z "$1" ] && notify-send "Display" "Mirror mode"
        ;;
    laptop-off)
        swaymsg output "$LAPTOP" disable
        swaymsg output "$EXTERNAL" enable
        echo "laptop-off" > "$STATE_FILE"
        [ -z "$1" ] && notify-send "Display" "Laptop screen off"
        ;;
    side-by-side)
        swaymsg output "$LAPTOP" enable pos 0 0
        swaymsg output "$EXTERNAL" enable pos "$LAPTOP_WIDTH" 0
        echo "side-by-side" > "$STATE_FILE"
        [ -z "$1" ] && notify-send "Display" "Side by side"
        ;;
esac
