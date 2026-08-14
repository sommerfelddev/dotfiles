#!/usr/bin/env dash
set -u

log="${XDG_RUNTIME_DIR:-/tmp}/display-recover.log"

outputs_json() {
  swaymsg -t get_outputs -r 2>/dev/null || printf '[]\n'
}

first_laptop() {
  jq -r '[.[] | select(.name | test("^eDP")) | .name] | first // empty'
}

externals() {
  jq -r '.[] | select(.name | test("^eDP") | not) | .name'
}

laptop_width() {
  jq -r --arg name "$1" '.[] | select(.name == $name) | .current_mode.width // .modes[0].width // 1920'
}

{
  printf '\n[%s] display recovery\n' "$(date -Is)"

  "$HOME/.config/sway/display-wake.sh" || true

  outputs=$(outputs_json)
  laptop=$(printf '%s\n' "$outputs" | first_laptop)
  width=1920

  if [ -n "$laptop" ]; then
    width=$(printf '%s\n' "$outputs" | laptop_width "$laptop")
    swaymsg output "$laptop" enable pos 0 0 || true
  fi

  printf '%s\n' "$outputs" | externals | while read -r output; do
    [ -n "$output" ] || continue
    swaymsg output "$output" power on || true
    sleep 0.2
    swaymsg output "$output" disable || true
    sleep 0.5
    swaymsg output "$output" enable pos "$width" 0 || true
  done

  swaymsg 'output * power on' || true
  brightnessctl -r || true
} >>"$log" 2>&1
