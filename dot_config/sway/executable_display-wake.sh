#!/usr/bin/env dash
set -u

brightnessctl -r >/dev/null 2>&1 || true
swaymsg 'output * power on' >/dev/null 2>&1 || true
sleep 0.2

"$HOME/.config/sway/display-toggle.sh" apply >/dev/null 2>&1 || true
