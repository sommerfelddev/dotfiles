#!/bin/sh
# Cycle display mode: laptop-off → side-by-side → mirror
# Usage: display-toggle.sh [init]
# Bound to F7 in sway config; also runs at startup with "init"

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/display-mode"
MIRROR_PID="${XDG_RUNTIME_DIR:-/tmp}/wl-mirror.pid"

OUTPUTS=$(swaymsg -t get_outputs -r)
LAPTOP=$(echo "$OUTPUTS" | jq -r '[.[] | select(.name | test("^eDP")) | .name] | first // empty')
EXTERNAL=$(echo "$OUTPUTS" | jq -r '[.[] | select(.name | test("^eDP") | not) | .name] | first // empty')

if [ -z "$EXTERNAL" ]; then
    [ -z "$1" ] && notify-send "Display" "No external display connected"
    exit 0
fi

if [ -z "$LAPTOP" ]; then
    exit 0
fi

# Stop any running wl-mirror
if [ -f "$MIRROR_PID" ]; then
    kill "$(cat "$MIRROR_PID")" 2>/dev/null || true
    rm -f "$MIRROR_PID"
fi

LAPTOP_WIDTH=$(echo "$OUTPUTS" | jq -r ".[] | select(.name == \"$LAPTOP\") | .current_mode.width")
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
        swaymsg output "$LAPTOP" enable || true
        swaymsg output "$EXTERNAL" enable || true
        swaymsg focus output "$EXTERNAL" || true
        wl-mirror "$LAPTOP" &
        echo $! > "$MIRROR_PID"
        sleep 0.3
        swaymsg focus output "$LAPTOP" || true
        echo "mirror" > "$STATE_FILE"
        [ -z "$1" ] && notify-send "Display" "Mirror mode"
        ;;
    laptop-off)
        swaymsg output "$LAPTOP" disable || true
        swaymsg output "$EXTERNAL" enable || true
        swaymsg workspace number 1 || true
        echo "laptop-off" > "$STATE_FILE"
        [ -z "$1" ] && notify-send "Display" "Laptop screen off"
        ;;
    side-by-side)
        swaymsg output "$LAPTOP" enable pos 0 0 || true
        swaymsg output "$EXTERNAL" enable pos "$LAPTOP_WIDTH" 0 || true
        echo "side-by-side" > "$STATE_FILE"
        [ -z "$1" ] && notify-send "Display" "Side by side"
        ;;
esac
