#!/bin/sh
# Waybar custom/lostfiles: shows count of filesystem entries not owned
# by any pacman package (and not on lostfiles' built-in safe-list).
# Source of truth is /run/lostfiles.txt, refreshed weekly by
# lostfiles.timer (system scope). Hidden when zero or report missing.
#
# Mako throttled to once per 7d via a stamp in $XDG_RUNTIME_DIR — the
# report itself only changes weekly so anything more frequent would
# re-fire on the same data.

set -eu

REPORT=/run/lostfiles.txt
STATE=${XDG_RUNTIME_DIR:-/tmp}/waybar-lostfiles-notified

emit_empty() {
  printf '{"text":"","class":"fresh","tooltip":""}\n'
  exit 0
}

[ -r "$REPORT" ] || emit_empty

count=$(grep -c . "$REPORT" 2>/dev/null || :)
case "$count" in '' | *[!0-9]*) count=0 ;; esac

[ "$count" -eq 0 ] && emit_empty

text="lost ${count}"
tooltip="${count} unowned file(s) under tracked dirs — click to review in \`nvim -R\`"
printf '{"text":"%s","class":"warn","tooltip":"%s"}\n' "$text" "$tooltip"

now=$(date +%s)
last_notified=0
if [ -f "$STATE" ]; then
  last_notified=$(cat "$STATE" 2>/dev/null || printf 0)
  case "$last_notified" in '' | *[!0-9]*) last_notified=0 ;; esac
fi

if [ $((now - last_notified)) -ge 604800 ] &&
  command -v notify-send >/dev/null 2>&1; then
  notify-send \
    --app-name=lostfiles \
    --urgency=normal \
    --icon=folder-documents \
    "Unowned files detected" \
    "${count} entries under tracked dirs aren't owned by any package. Review at your leisure."
  printf '%s\n' "$now" >"$STATE"
fi
