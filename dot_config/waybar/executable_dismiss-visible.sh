#!/bin/sh
# Dismiss currently-visible mako notifications and record their ids in the
# shared "dismissed" set so they don't linger as pending in waybar.
#
# Usage: dismiss-visible.sh [top|all]   (default: top)
#
# Coordinates with mako-status.sh and mako-history.py via
# $XDG_RUNTIME_DIR/mako-dismissed (one id per line, per-session).

set -eu

mode=${1:-top}
state=${XDG_RUNTIME_DIR:-/tmp}/mako-dismissed
mkdir -p "$(dirname "$state")"
: >>"$state"

command -v makoctl >/dev/null 2>&1 || exit 0

# This makoctl has no -f; extract ids from the text dump.
list_ids() {
  makoctl list 2>/dev/null |
    sed -n 's/^Notification \([0-9][0-9]*\):.*/\1/p'
}

case "$mode" in
  top)
    id=$(list_ids | head -n1 || true)
    [ -n "${id:-}" ] && printf '%s\n' "$id" >>"$state"
    makoctl dismiss
    ;;
  all)
    list_ids >>"$state" || true
    makoctl dismiss --all
    ;;
  *)
    echo "usage: $0 [top|all]" >&2
    exit 2
    ;;
esac
