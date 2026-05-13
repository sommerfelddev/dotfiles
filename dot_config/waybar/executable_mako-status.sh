#!/bin/sh
# Waybar status: count of *pending* notifications, where pending = ids in
# mako's history that have NOT been explicitly dismissed by the user via
# Mod+n / Mod+Shift+n / the history picker.
#
# State file: $XDG_RUNTIME_DIR/mako-dismissed (per-session, plain id list).

set -eu

if ! command -v makoctl >/dev/null 2>&1; then
  printf '{"text":"","tooltip":"mako not installed","class":"off"}
'
  exit 0
fi

state=${XDG_RUNTIME_DIR:-/tmp}/mako-dismissed
: >>"$state"

# Visible notifications also count as pending (they aren't in history yet).
visible_ids=$(makoctl list -f '%i' 2>/dev/null || true)
history_ids=$(makoctl history -f '%i' 2>/dev/null || true)
all_ids=$(printf '%s
%s
' "$visible_ids" "$history_ids" \
            | grep -E '^[0-9]+$' | sort -u || true)

# Prune stale ids (no longer present in mako) from the dismissed file.
if [ -s "$state" ] && [ -n "$all_ids" ]; then
  tmp=$(mktemp)
  printf '%s
' "$all_ids" >"$tmp.all"
  grep -Fxf "$tmp.all" "$state" >"$tmp" 2>/dev/null || :
  mv "$tmp" "$state"
  rm -f "$tmp.all"
fi

if [ -z "$all_ids" ]; then
  pending=0
else
  pending=$(printf '%s
' "$all_ids" | grep -Fxvf "$state" | grep -c . || true)
fi

if [ "$pending" -gt 0 ]; then
  printf '{"text":"󰂞 %s","tooltip":"%s pending","class":"pending"}
' \
    "$pending" "$pending"
else
  printf '{"text":"󰂜","tooltip":"no pending notifications","class":"empty"}
'
fi
