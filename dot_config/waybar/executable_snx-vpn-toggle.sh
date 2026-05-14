#!/bin/sh
# Toggle the snx-rs (Check Point) tunnel. Connect goes through the
# snxctl-chromium wrapper so SAML lands in the flatpak ungoogled
# chromium (LibreWolf blocks the 127.0.0.1:7779 callback).
#
# Refresh the waybar custom/snx-vpn module immediately with SIGRTMIN+9.
set -eu

state=$(timeout 2 snxctl status 2>/dev/null || echo Disconnected)

case "$state" in
  *"Disconnected"*)
    # Detach so waybar doesn't block waiting for SAML. The inner script
    # re-signals waybar when the connect attempt finishes so the badge
    # flips immediately to its final state.
    # shellcheck disable=SC2016
    setsid -f sh -c '
      "$HOME/.local/bin/snxctl-chromium" >/tmp/snxctl-chromium.log 2>&1
      pid=$(pidof waybar) && kill -SIGRTMIN+9 $pid 2>/dev/null || true
    '
    ;;
  *)
    snxctl disconnect >/dev/null 2>&1 || true
    ;;
esac

pid=$(pidof waybar || true)
[ -n "$pid" ] && kill -SIGRTMIN+9 "$pid" 2>/dev/null || true
