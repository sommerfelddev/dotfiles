#!/bin/sh
# Cycle display mode: mirror → laptop-off → side-by-side
# Bound to F7 in sway config

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/display-mode"
CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "mirror")

LAPTOP=$(swaymsg -t get_outputs -r | jq -r '.[] | select(.name | test("eDP")) | .name')
EXTERNAL=$(swaymsg -t get_outputs -r | jq -r '[.[] | select(.name | test("eDP") | not) | .name] | first // empty')

if [ -z "$EXTERNAL" ]; then
    notify-send "Display" "No external display connected"
    exit 0
fi

# Get laptop panel width for side-by-side positioning
LAPTOP_WIDTH=$(swaymsg -t get_outputs -r | jq -r ".[] | select(.name == \"$LAPTOP\") | .rect.width")
[ -z "$LAPTOP_WIDTH" ] && LAPTOP_WIDTH=1920

case "$CURRENT" in
    mirror)
        swaymsg output "$LAPTOP" disable
        echo "laptop-off" > "$STATE_FILE"
        notify-send "Display" "Laptop screen off"
        ;;
    laptop-off)
        swaymsg output "$LAPTOP" enable pos 0 0
        swaymsg output "$EXTERNAL" pos "$LAPTOP_WIDTH" 0
        echo "side-by-side" > "$STATE_FILE"
        notify-send "Display" "Side by side"
        ;;
    side-by-side|*)
        swaymsg output "$LAPTOP" enable pos 0 0
        swaymsg output "$EXTERNAL" pos 0 0
        echo "mirror" > "$STATE_FILE"
        notify-send "Display" "Mirror mode"
        ;;
esac
