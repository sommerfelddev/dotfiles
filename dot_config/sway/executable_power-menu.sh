#!/bin/sh
# Keyboard-driven power menu via wofi --dmenu (j/k navigation).
set -eu

choice=$(printf '%s\n' \
  "  Lock" \
  "  Suspend" \
  "  Logout" \
  "  Reboot" \
  "  Poweroff" |
  wofi --dmenu --hide-search --prompt='power' \
    --style "$HOME/.config/wofi/style.css")

case "$choice" in
  *Lock)
    playerctl -a pause
    exec swaylock -f -e -c 000000
    ;;
  *Suspend)
    playerctl -a pause
    exec systemctl suspend
    ;;
  *Logout) exec swaymsg exit ;;
  *Reboot) exec systemctl reboot ;;
  *Poweroff) exec systemctl poweroff ;;
esac
