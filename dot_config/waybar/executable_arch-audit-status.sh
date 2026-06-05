#!/usr/bin/env dash
# Waybar custom/arch-audit: shows count of installed packages with known
# CVEs that already have a fix available in the repos. Source of truth
# is /run/arch-audit.txt, refreshed daily by arch-audit.timer (system
# scope). Hidden when zero or report missing.
#
# Mako throttled to once per 24h via a stamp in $XDG_RUNTIME_DIR.

set -eu

REPORT=/run/arch-audit.txt
STATE=${XDG_RUNTIME_DIR:-/tmp}/waybar-arch-audit-notified

emit_empty() {
  printf '{"text":"","class":"fresh","tooltip":""}\n'
  exit 0
}

[ -r "$REPORT" ] || emit_empty

count=$(grep -c . "$REPORT" 2>/dev/null || :)
case "$count" in '' | *[!0-9]*) count=0 ;; esac

[ "$count" -eq 0 ] && emit_empty

text="CVE ${count}"
tooltip="${count} package(s) with fixable CVEs — click to view, then run \`just update\`"
printf '{"text":"%s","class":"critical","tooltip":"%s"}\n' "$text" "$tooltip"

now=$(date +%s)
last_notified=0
if [ -f "$STATE" ]; then
  last_notified=$(cat "$STATE" 2>/dev/null || printf 0)
  case "$last_notified" in '' | *[!0-9]*) last_notified=0 ;; esac
fi

if [ $((now - last_notified)) -ge 86400 ] &&
  command -v notify-send >/dev/null 2>&1; then
  notify-send \
    --app-name=arch-audit \
    --urgency=critical \
    --icon=security-medium \
    "Security updates available" \
    "${count} installed package(s) have fixable CVEs. Run \`just update\`."
  printf '%s\n' "$now" >"$STATE"
fi
