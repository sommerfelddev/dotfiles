#!/bin/sh
# Keyboard-driven power menu via fuzzel --dmenu.
set -eu

choice=$(printf '%s\n' \
    "  Lock" \
    "  Suspend" \
    "  Logout" \
    "  Reboot" \
    "  Poweroff" \
    | fuzzel --dmenu --prompt='power: ' --lines=5 --width=20)

case "$choice" in
    *Lock)     playerctl -a pause; exec swaylock -f -e -c 000000 ;;
    *Suspend)  playerctl -a pause; exec systemctl suspend ;;
    *Logout)   exec swaymsg exit ;;
    *Reboot)   exec sudo /usr/bin/reboot ;;
    *Poweroff) exec sudo /usr/bin/poweroff ;;
esac
