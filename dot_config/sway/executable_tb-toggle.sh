#!/bin/sh
# Toggle the Thunderbird main window between the current workspace (tiled)
# and a hidden stash workspace. If Thunderbird isn't running yet, launch it —
# the for_window rule in sway config will mark and park it on the stash.

set -eu

STASH=_tb
MARK=tb-main

tree=$(swaymsg -t get_tree)

current_ws=$(printf '%s' "$tree" \
    | jq -r 'first(.. | objects | select(.type=="workspace" and .focused) | .name) // empty')

tb_ws=$(printf '%s' "$tree" \
    | jq -r --arg m "$MARK" '
        first(
          .. | objects
          | select(.type=="workspace")
          | select([.. | objects | select(.marks? // [] | index($m))] | length > 0)
          | .name
        ) // empty')

if [ -z "$tb_ws" ]; then
    exec thunderbird
fi

if [ "$tb_ws" = "$current_ws" ]; then
    swaymsg "[con_mark=\"$MARK\"] move container to workspace $STASH" >/dev/null
else
    swaymsg "[con_mark=\"$MARK\"] move container to workspace $current_ws, focus" >/dev/null
fi
