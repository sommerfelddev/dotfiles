#!/usr/bin/env dash
# Keyboard-driven power menu via wofi --dmenu (j/k navigation).
set -eu

choice=$(printf '%s\n' \
  "  Lock" \
  "  Suspend" \
  "  Logout" \
  "  Reboot" \
  "  Poweroff" |
  wofi --dmenu --prompt='power' \
    --matching=fuzzy --insensitive \
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
