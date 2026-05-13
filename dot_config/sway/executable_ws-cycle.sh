#!/bin/sh
# Cycle to the next/previous workspace on the current output, skipping
# the _tb stash workspace. Usage: ws-cycle.sh next|prev
set -eu

DIR=${1:?usage: ws-cycle.sh next|prev}
SKIP=_tb

swaymsg -t get_workspaces | jq -r --arg dir "$DIR" --arg skip "$SKIP" '
    (map(select(.focused)) | .[0]) as $cur
    | map(select(.output == $cur.output and .name != $skip))
    | sort_by(.num, .name) as $list
    | ($list | map(.name == $cur.name) | index(true)) as $i
    | if $i == null then $list[0].name
      elif $dir == "next" then $list[(($i + 1) % ($list | length))].name
      else $list[(($i - 1 + ($list | length)) % ($list | length))].name
      end
' | xargs -I{} swaymsg workspace {} >/dev/null
