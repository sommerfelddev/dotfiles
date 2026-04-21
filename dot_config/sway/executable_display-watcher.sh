#!/bin/sh
# Watch sway output events. When the set of connected external displays
# changes (plug/unplug), re-apply the preferred layout via display-toggle.sh.
# Manual F7 toggles don't trip this because they don't change external count.
set -eu

has_external() {
  swaymsg -t get_outputs -r |
    jq -e '[.[] | select(.name | test("^eDP") | not)] | length > 0' >/dev/null
}

prev=$(has_external && echo yes || echo no)

swaymsg -t subscribe -m '["output"]' | while read -r _; do
  cur=$(has_external && echo yes || echo no)
  if [ "$cur" != "$prev" ]; then
    ~/.config/sway/display-toggle.sh init
    prev="$cur"
  fi
done
