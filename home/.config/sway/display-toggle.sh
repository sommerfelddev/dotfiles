#!/bin/sh
# Toggle display mode: laptop-off ↔ side-by-side
# Bound to F7 in sway config; also runs at startup with "init"

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/display-mode"

OUTPUTS=$(swaymsg -t get_outputs -r)
LAPTOP=$(echo "$OUTPUTS" | jq -r '[.[] | select(.name | test("^eDP")) | .name] | first // empty')
EXTERNAL=$(echo "$OUTPUTS" | jq -r '[.[] | select(.name | test("^eDP") | not) | .name] | first // empty')

if [ -z "$EXTERNAL" ]; then
    [ -z "$1" ] && notify-send "Display" "No external display connected"
    exit 0
fi

[ -z "$LAPTOP" ] && exit 0

LAPTOP_WIDTH=$(echo "$OUTPUTS" | jq -r ".[] | select(.name == \"$LAPTOP\") | .current_mode.width // .modes[0].width")
[ -z "$LAPTOP_WIDTH" ] && LAPTOP_WIDTH=1920

if [ "$1" = "init" ]; then
    NEXT="laptop-off"
else
    CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "laptop-off")
    case "$CURRENT" in
        laptop-off) NEXT="side-by-side" ;;
        *) NEXT="laptop-off" ;;
    esac
fi

case "$NEXT" in
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
