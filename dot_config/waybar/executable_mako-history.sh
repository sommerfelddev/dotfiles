#!/bin/sh
# Fuzzel picker over mako's notification history. Read-only: mako has no
# API to re-invoke an arbitrary history item, so the selected entry is
# copied to the clipboard for reference. Use makoctl restore to bring the
# most recent dismissed notification back to the active list.

set -eu

selection=$(
  makoctl history | jq -r '
    def v: if type == "object" and has("data") then .data else . end;
    [.. | objects | select(has("summary") and has("app-name"))]
    | .[]
    | "[\(.["app-name"] | v)] \(.summary | v) — \((.body | v) // "")"
  ' | fuzzel --dmenu --prompt 'History: '
)

if [ -n "$selection" ]; then
  printf '%s' "$selection" | wl-copy
fi
