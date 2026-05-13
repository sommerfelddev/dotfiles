#!/bin/sh
# Waybar status: count of currently-visible mako notifications. With
# default-timeout=0 in mako/config, "visible" == "pending"; once a
# notification is dismissed it's gone and never comes back.

set -eu

if ! command -v makoctl >/dev/null 2>&1; then
  printf '{"text":"","tooltip":"mako not installed","class":"off"}\n'
  exit 0
fi

count=$(makoctl list 2>/dev/null |
  grep -c '^Notification [0-9][0-9]*:' || true)

if [ "$count" -gt 0 ]; then
  printf '{"text":"󰂞 %s","tooltip":"%s pending","class":"pending"}\n' \
    "$count" "$count"
else
  printf '{"text":"󰂜","tooltip":"no pending notifications","class":"empty"}\n'
fi
