#!/bin/sh
# Fuzzel picker over mako's notification history. Read-only: mako has no
# API to re-invoke an arbitrary history item, so the selected entry is
# copied to the clipboard for reference. Use makoctl restore to bring the
# most recent dismissed notification back to the active list.

set -eu

selection=$(
  makoctl history --format '[%a] %s — %b' |
    fuzzel --dmenu --prompt 'History: '
)

if [ -n "$selection" ]; then
  printf '%s' "$selection" | wl-copy
fi
