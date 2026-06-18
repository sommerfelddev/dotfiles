#!/usr/bin/env dash
# Waybar custom/update: gentle reminder that the system hasn't been
# upgraded recently. Source of truth is /var/log/pacman.log — the last
# "[PACMAN] starting full system upgrade" entry. No daemon, no -Sy
# polling, no opinion about *which* updates are pending; this only
# tracks whether you've run `pacman -Syu` lately.
#
# States, by hours since last full upgrade:
#   < 24h         empty (hidden via :empty rule in style.css)
#   24h – 168h    warn      → yellow icon  + normal-urgency mako once/24h
#   ≥ 168h (7d)  critical  → red icon     + critical mako once/24h
#
# The mako notification is throttled by a stamp file in $XDG_RUNTIME_DIR
# so reboots reset it (post-reboot is a fine moment to be reminded).

set -eu

LOG=/var/log/pacman.log
STATE=${XDG_RUNTIME_DIR:-/tmp}/waybar-update-notified

emit_empty() {
  printf '{"text":"","class":"fresh","tooltip":""}\n'
  exit 0
}

[ -r "$LOG" ] || emit_empty

# Pacman log lines look like: [2026-05-07T08:30:00+0000] [PACMAN] starting full system upgrade
last=$(grep -F '[PACMAN] starting full system upgrade' "$LOG" |
  tail -n1 |
  sed -n 's/^\[\([^]]*\)\].*/\1/p')
[ -n "$last" ] || emit_empty

last_epoch=$(date -d "$last" +%s 2>/dev/null) || emit_empty
now=$(date +%s)
elapsed=$((now - last_epoch))
hours=$((elapsed / 3600))
days=$((hours / 24))

[ "$hours" -lt 24 ] && emit_empty

# Tier + human-friendly duration
if [ "$days" -ge 7 ]; then
  state=critical
  urgency=critical
else
  state=warn
  urgency=normal
fi

if [ "$days" -ge 2 ]; then
  ago="${days}d"
elif [ "$days" -ge 1 ]; then
  ago="1d"
else
  ago="${hours}h"
fi

text="󰚰 ${ago}"
tooltip="System upgrade last ran ${ago} ago — click to run \`just update\`"
printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$state" "$tooltip"

# Throttle mako: at most one reminder per 24h.
last_notified=0
if [ -f "$STATE" ]; then
  last_notified=$(cat "$STATE" 2>/dev/null || printf 0)
  case "$last_notified" in
    '' | *[!0-9]*) last_notified=0 ;;
  esac
fi

if [ $((now - last_notified)) -ge 86400 ] &&
  command -v notify-send >/dev/null 2>&1; then
  notify-send \
    --app-name=system-update \
    --urgency="$urgency" \
    --icon=system-software-update \
    "System upgrade reminder" \
    "Last upgrade: ${ago} ago. Run \`just update\` when convenient."
  printf '%s\n' "$now" >"$STATE"
fi
