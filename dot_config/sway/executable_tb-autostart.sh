#!/usr/bin/env dash
# Launch Thunderbird and stash the main window into the scratchpad once sway
# marks it. Used at sway startup so TB is running but hidden from the outset.
# Invoking Super+t (tb-toggle.sh) while TB isn't running takes a different
# path and leaves the window tiled on the current workspace.

set -eu

MARK=tb-main
BRIDGE_HOST=127.0.0.1
BRIDGE_PORT=1143

# protonmail-bridge opens the IMAP socket early (before the keyring is
# unlocked), so "port is listening" is not enough — TB will race and pop up
# "failed to login to 127.0.0.1". Wait for the real IMAP '* OK' greeting,
# which the bridge only sends once it can actually service logins.
for _ in $(seq 1 300); do
  banner=$(ncat -w 1 -i 1 "$BRIDGE_HOST" "$BRIDGE_PORT" </dev/null 2>/dev/null | head -c 64)
  case "$banner" in
    "* OK"*) break ;;
  esac
  sleep 0.2
done

# Small grace period so the SMTP listener (1025) catches up too.
sleep 10

flatpak run org.mozilla.thunderbird &

for _ in $(seq 1 200); do
  if swaymsg -t get_tree | jq -e --arg m "$MARK" '
        [.. | objects | select(.marks? // [] | index($m))] | length > 0
    ' >/dev/null 2>&1; then
    swaymsg "[con_mark=\"$MARK\"] move container to scratchpad" >/dev/null
    exit 0
  fi
  sleep 0.1
done
