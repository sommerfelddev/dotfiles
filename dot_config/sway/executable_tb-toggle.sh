#!/bin/sh
# Toggle the Thunderbird main window between the sway scratchpad and the
# current workspace (tiled). If Thunderbird isn't running yet, launch it —
# the for_window rule in sway config will mark it and stash it.

set -eu

MARK=tb-main

# Find the workspace ancestor name of the con carrying MARK.
# __i3_scratch means the window is currently stashed in the scratchpad.
tb_ws=$(swaymsg -t get_tree | jq -r --arg m "$MARK" '
    first(
      .. | objects
      | select(.type=="workspace")
      | select([.. | objects | select(.marks? // [] | index($m))] | length > 0)
      | .name
    ) // empty')

if [ -z "$tb_ws" ]; then
    exec thunderbird
fi

if [ "$tb_ws" = "__i3_scratch" ]; then
    # scratchpad show reveals it as floating; floating disable tiles it on the
    # current workspace.
    swaymsg "[con_mark=\"$MARK\"] scratchpad show, floating disable" >/dev/null
else
    # Criteria-based move can cause sway to follow focus to the originating
    # workspace. Pin focus back to where we started.
    current_ws=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .name')
    swaymsg "[con_mark=\"$MARK\"] move container to scratchpad" >/dev/null
    swaymsg "workspace \"$current_ws\"" >/dev/null
fi
