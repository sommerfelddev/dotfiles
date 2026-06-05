#!/usr/bin/env dash
# Waybar custom/snx-vpn module: report the snx-rs (Check Point) tunnel
# state. `snxctl status` is fast (talks over a local UDS to the daemon)
# but might briefly stall during connect; cap it with `timeout`.

# Bail out if the daemon socket isn't even there (snx-rs.service stopped).
out=$(timeout 2 snxctl status 2>/dev/null) || out=

case "$out" in
  '' | *"Disconnected"*)
    printf '{"text":"<span color=\\"#928374\\"><s>󰌾 SNX</s></span>","class":"down","tooltip":"snx-rs disconnected — click to connect"}\n'
    ;;
  *"Connecting"* | *"MFA pending"*)
    printf '{"text":"<span color=\\"#fabd2f\\">󰌾 SNX…</span>","class":"connecting","tooltip":"%s"}\n' "$(echo "$out" | head -1)"
    ;;
  *)
    tooltip=$(echo "$out" | sed 's/"/\\"/g' | awk 'BEGIN{ORS="\\n"}{print}')
    printf '{"text":"<span color=\\"#b8bb26\\">󰌾 SNX</span>","class":"up","tooltip":"%s"}\n' "$tooltip"
    ;;
esac
