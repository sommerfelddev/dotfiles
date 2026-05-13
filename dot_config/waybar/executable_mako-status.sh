#!/bin/sh
# Emit waybar JSON with the mako notification count. Falls back to 0 when
# mako is not running so waybar doesn't blink errors.
set -eu

if ! command -v makoctl >/dev/null 2>&1; then
  printf '{"text":"","tooltip":"mako not installed","class":"off"}\n'
  exit 0
fi

count=$(makoctl history 2>/dev/null | grep -c '^Notification ' || true)
pending=$(makoctl list 2>/dev/null | grep -c '^Notification ' || true)

if [ "$pending" -gt 0 ]; then
  text="󰂞 $pending"
  class="pending"
elif [ "$count" -gt 0 ]; then
  text="󱇨 $count"
  class="history"
else
  text="󰂜"
  class="empty"
fi

printf '{"text":"%s","tooltip":"%s pending / %s history","class":"%s"}\n' \
  "$text" "$pending" "$count" "$class"
