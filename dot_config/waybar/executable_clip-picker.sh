#!/usr/bin/env dash
# Clipboard picker on top of cliphist + wofi (vim-nav, hide-search,
# Alt-d to delete the highlighted entry).
#
# Modes:
#   pick    Enter pastes (cliphist decode | wl-copy)
#   delete  Enter deletes (cliphist delete)
#
# Alt-d in pick mode deletes the highlighted entry without pasting.

set -u

mode=${1:-pick}
style=$HOME/.config/wofi/style.css

set +e
selection=$(
  cliphist list |
    wofi --dmenu --hide-search --prompt Clip \
      --define key_custom_0=Alt-d \
      ${style:+--style "$style"}
)
rc=$?
set -e

[ -z "$selection" ] && exit 0

case "$mode:$rc" in
  pick:0) printf '%s' "$selection" | cliphist decode | wl-copy ;;
  pick:10) printf '%s' "$selection" | cliphist delete ;;
  delete:0 | delete:10) printf '%s' "$selection" | cliphist delete ;;
esac
