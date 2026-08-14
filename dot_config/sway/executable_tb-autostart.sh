#!/usr/bin/env dash
# Launch Thunderbird and stash the main window into the scratchpad once sway
# marks it. Used at sway startup so TB is running but hidden from the outset.
# Invoking Super+t (tb-toggle.sh) while TB isn't running takes a different
# path and leaves the window tiled on the current workspace.

set -eu

MARK=tb-main
APP_ID=org.mozilla.thunderbird
TITLE_SUFFIX="Mozilla Thunderbird"
BRIDGE_HOST=127.0.0.1
BRIDGE_IMAP_PORT=1144
BRIDGE_SMTP_PORT=1016

# protonmail-bridge opens the IMAP socket early (before the keyring is
# unlocked), so "port is listening" is not enough — TB will race and pop up
# "failed to login to 127.0.0.1". Wait for the real IMAP '* OK' greeting,
# which the bridge only sends once it can actually service logins.
for _ in $(seq 1 300); do
  banner=$(ncat -w 1 -i 1 "$BRIDGE_HOST" "$BRIDGE_IMAP_PORT" </dev/null 2>/dev/null | head -c 64)
  case "$banner" in
    "* OK"*) break ;;
  esac
  sleep 0.2
done

# SMTP tends to come up after IMAP; wait briefly so TB sees both local servers.
for _ in $(seq 1 50); do
  ncat -z -w 1 "$BRIDGE_HOST" "$BRIDGE_SMTP_PORT" 2>/dev/null && break
  sleep 0.2
done

flatpak run org.mozilla.thunderbird &

for _ in $(seq 1 200); do
  tb_id=$(swaymsg -t get_tree | jq -r \
    --arg app "$APP_ID" --arg suffix "$TITLE_SUFFIX" '
      first(
        .. | objects
        | select(.app_id? == $app)
        | select((.name? // "") | endswith($suffix))
        | .id
      ) // empty')
  if [ -n "$tb_id" ]; then
    swaymsg "[con_id=\"$tb_id\"] mark --add $MARK" >/dev/null
    swaymsg "[con_id=\"$tb_id\"] move container to scratchpad" >/dev/null
    exit 0
  fi
  sleep 0.1
done
