#!/bin/sh
# Launch Thunderbird and stash the main window into the scratchpad once sway
# marks it. Used at sway startup so TB is running but hidden from the outset.
# Invoking Super+t (tb-toggle.sh) while TB isn't running takes a different
# path and leaves the window tiled on the current workspace.

set -eu

MARK=tb-main
BRIDGE_PORT=1143

# Wait for protonmail-bridge's IMAP listener before launching Thunderbird so
# TB doesn't pop up a "failed to login to 127.0.0.1" error on cold boot. Give
# up after ~15s and launch anyway — the user can reconnect manually.
for _ in $(seq 1 150); do
  if ss -ltnH "sport = :$BRIDGE_PORT" 2>/dev/null | grep -q .; then
    break
  fi
  sleep 0.1
done

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
