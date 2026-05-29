#!/bin/sh
# Keyboard-driven power menu via wofi --dmenu (j/k navigation).
set -eu

# Suspend entry intentionally omitted while suspend is disabled
# system-wide. See etc/systemd/logind.conf.d/20-no-suspend.conf.
choice=$(printf '%s\n' \
  "  Lock" \
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
  *Logout) exec swaymsg exit ;;
  *Reboot) exec systemctl reboot ;;
  *Poweroff) exec systemctl poweroff ;;
esac
