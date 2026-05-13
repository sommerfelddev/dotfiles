#!/bin/sh
# Launch Thunderbird and stash the main window into the scratchpad once sway
# marks it. Used at sway startup so TB is running but hidden from the outset.
# Invoking Super+t (tb-toggle.sh) while TB isn't running takes a different
# path and leaves the window tiled on the current workspace.

set -eu

MARK=tb-main

thunderbird &

for _ in $(seq 1 200); do
    if swaymsg -t get_tree | jq -e --arg m "$MARK" '
        [.. | objects | select(.marks? // [] | index($m))] | length > 0
    ' >/dev/null 2>&1; then
        swaymsg "[con_mark=\"$MARK\"] move container to scratchpad" >/dev/null
        exit 0
    fi
    sleep 0.1
done
