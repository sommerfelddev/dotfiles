#!/bin/sh
# Restore the most recently closed mako notification and remove its id
# from the dismissed-set so it counts as pending again.

set -eu

state=${XDG_RUNTIME_DIR:-/tmp}/mako-dismissed
: >>"$state"

command -v makoctl >/dev/null 2>&1 || exit 0

# mako's history is most-recent-first; the next restore() target is the
# top of the list at the time of the call.
top_id=$(makoctl history -f '%i' 2>/dev/null | head -n1 || true)
makoctl restore || true

if [ -n "${top_id:-}" ] && [ -s "$state" ]; then
  tmp=$(mktemp)
  grep -Fxv "$top_id" "$state" >"$tmp" || :
  mv "$tmp" "$state"
fi
