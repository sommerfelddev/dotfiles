#!/usr/bin/env dash
# Waybar custom/failed-units: shows count of failed systemd units across
# the system bus and the current user's session bus. Hidden when zero.
# Mako fires only on transition upward (count went up since last check),
# so transient failures you've already seen don't re-nag.
#
# Click handler shows `systemctl --failed` and `systemctl --user --failed`
# in a floating ghostty.

set -eu

STATE=${XDG_RUNTIME_DIR:-/tmp}/waybar-failed-units-prev

emit_empty() {
  printf '{"text":"","class":"fresh","tooltip":""}\n'
  printf 0 >"$STATE" 2>/dev/null || :
  exit 0
}

count_failed() {
  systemctl "$@" --failed --no-legend --plain 2>/dev/null |
    grep -c . || :
}

sys=$(count_failed)
usr=$(count_failed --user)
case "$sys" in '' | *[!0-9]*) sys=0 ;; esac
case "$usr" in '' | *[!0-9]*) usr=0 ;; esac
total=$((sys + usr))

[ "$total" -eq 0 ] && emit_empty

text="failed ${total}"
tooltip="${sys} system + ${usr} user unit(s) failed — click for details"
printf '{"text":"%s","class":"critical","tooltip":"%s"}\n' "$text" "$tooltip"

prev=0
if [ -f "$STATE" ]; then
  prev=$(cat "$STATE" 2>/dev/null || printf 0)
  case "$prev" in '' | *[!0-9]*) prev=0 ;; esac
fi

if [ "$total" -gt "$prev" ] &&
  command -v notify-send >/dev/null 2>&1; then
  notify-send \
    --app-name=systemd \
    --urgency=critical \
    --icon=dialog-error \
    "Systemd unit failure" \
    "${sys} system + ${usr} user unit(s) failed. Click the bar entry for details."
fi

printf '%s' "$total" >"$STATE"
