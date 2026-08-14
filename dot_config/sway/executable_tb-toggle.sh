#!/usr/bin/env dash
# Toggle the Thunderbird main window between the sway scratchpad and the
# current workspace (tiled). If Thunderbird isn't running yet, launch it.

set -eu

MARK=tb-main
APP_ID=org.mozilla.thunderbird
TITLE_SUFFIX="Mozilla Thunderbird"

tree=$(swaymsg -t get_tree)
tb_id=$(printf '%s\n' "$tree" | jq -r --arg m "$MARK" '
    first(
      .. | objects
      | select(.marks? // [] | index($m))
      | .id
    ) // empty')

if [ -z "$tb_id" ]; then
  tb_id=$(printf '%s\n' "$tree" | jq -r \
    --arg app "$APP_ID" --arg suffix "$TITLE_SUFFIX" '
      first(
        .. | objects
        | select(.app_id? == $app)
        | select((.name? // "") | endswith($suffix))
        | .id
      ) // empty')
  if [ -z "$tb_id" ]; then
    exec flatpak run org.mozilla.thunderbird
  fi
  swaymsg "[con_id=\"$tb_id\"] mark --add $MARK" >/dev/null
fi

# __i3_scratch means the window is currently stashed in the scratchpad.
tb_ws=$(printf '%s\n' "$tree" | jq -r --argjson id "$tb_id" '
    first(
      .. | objects
      | select(.type=="workspace")
      | select([.. | objects | select(.id? == $id)] | length > 0)
      | .name
    ) // empty')

if [ "$tb_ws" = "__i3_scratch" ]; then
  # scratchpad show reveals it as floating; floating disable tiles it on the
  # current workspace.
  swaymsg "[con_id=\"$tb_id\"] scratchpad show, floating disable" >/dev/null
else
  # Criteria-based move can cause sway to follow focus to the originating
  # workspace. Pin focus back to where we started.
  current_ws=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .name')
  swaymsg "[con_id=\"$tb_id\"] move container to scratchpad" >/dev/null
  swaymsg "workspace \"$current_ws\"" >/dev/null
fi
