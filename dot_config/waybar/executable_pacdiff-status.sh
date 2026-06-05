#!/usr/bin/env dash
# Waybar custom/pacdiff: shows count of unresolved .pacnew/.pacsave files.
# Source of truth is `pacdiff -o` (output mode — lists differing files,
# does nothing). Hidden when zero. Mako fires once when the count goes
# from "no problems" to "non-zero" (i.e. on the post-`pacman -Syu`
# settle), so you're nudged exactly once per upgrade wave.
#
# Click handler runs `DIFFPROG='nvim -d' sudo pacdiff` in a floating
# ghostty. DIFFPROG is propagated through sudo-rs by the env_keep policy
# in etc/sudoers-rs (no -E needed — env_keep is unconditional pass-through).

set -eu

STATE=${XDG_RUNTIME_DIR:-/tmp}/waybar-pacdiff-prev

emit_empty() {
  printf '{"text":"","class":"fresh","tooltip":""}\n'
  printf 0 >"$STATE" 2>/dev/null || :
  exit 0
}

command -v pacdiff >/dev/null 2>&1 || emit_empty

count=$(pacdiff -o 2>/dev/null | grep -c . || :)
case "$count" in
  '' | *[!0-9]*) count=0 ;;
esac

[ "$count" -eq 0 ] && emit_empty

text="pacdiff ${count}"
tooltip="${count} unresolved .pacnew/.pacsave file(s) — click to merge with \`nvim -d\`"
printf '{"text":"%s","class":"warn","tooltip":"%s"}\n' "$text" "$tooltip"

prev=0
if [ -f "$STATE" ]; then
  prev=$(cat "$STATE" 2>/dev/null || printf 0)
  case "$prev" in
    '' | *[!0-9]*) prev=0 ;;
  esac
fi

if [ "$prev" -eq 0 ] && [ "$count" -gt 0 ] &&
  command -v notify-send >/dev/null 2>&1; then
  notify-send \
    --app-name=pacdiff \
    --urgency=normal \
    --icon=text-x-generic \
    "Pacman config files need merging" \
    "${count} .pacnew/.pacsave file(s). Click the bar entry to run pacdiff."
fi

printf '%s' "$count" >"$STATE"
