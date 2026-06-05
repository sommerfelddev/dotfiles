#!/usr/bin/env dash
# Fetch the current VPN TOTP from pass-otp and type it into the focused
# surface via wtype. If wtype isn't available or fails (focused surface
# lacks virtual-keyboard support, e.g. an Xwayland app), copy the code
# to the Wayland clipboard instead and notify so the user can Ctrl+V it.
set -eu

code=$(pass otp show vpn/totp 2>/dev/null | tr -d ' \t\n\r') || {
  notify-send -u critical "VPN OTP" "pass otp show vpn/totp failed"
  exit 1
}

if [ -z "$code" ]; then
  notify-send -u critical "VPN OTP" "empty code from pass-otp"
  exit 1
fi

if command -v wtype >/dev/null 2>&1 && wtype -- "$code" 2>/dev/null; then
  exit 0
fi

printf '%s' "$code" | wl-copy
notify-send "VPN OTP" "Typed via wtype failed — code copied to clipboard"
