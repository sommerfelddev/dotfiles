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

case "$mode" in
  top)
    id=$(makoctl list -f '%i' 2>/dev/null | head -n1 || true)
    [ -n "${id:-}" ] && printf '%s\n' "$id" >>"$state"
    makoctl dismiss
    ;;
  all)
    makoctl list -f '%i' 2>/dev/null >>"$state" || true
    makoctl dismiss --all
    ;;
  *)
    echo "usage: $0 [top|all]" >&2
    exit 2
    ;;
esac
