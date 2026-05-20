#!/bin/sh
# Toggle the snx-rs (Check Point) tunnel.
#
# Refresh the waybar custom/snx-vpn module immediately with SIGRTMIN+9.
set -eu

state=$(timeout 2 snxctl status 2>/dev/null || echo Disconnected)

case "$state" in
  *"Disconnected"*)
    setsid -f snxctl connect >/tmp/snxctl.log 2>&1 &
    ;;
  *)
    snxctl disconnect >/dev/null 2>&1 || true
    ;;
esac

pid=$(pidof waybar || true)
if [ -n "$pid" ]; then kill -SIGRTMIN+9 "$pid" 2>/dev/null || true; fi
