#!/usr/bin/env dash
# Emit waybar JSON with the count of unread messages in the protonmail-bridge
# IMAP Inbox. Requires bridge credentials in `pass` at the paths below; the
# bridge prints them via `protonmail-bridge --cli` → `info`.
#
# The on-click handler in waybar config drives tb-toggle.sh, so a click on
# the badge brings Thunderbird out of the scratchpad (or launches it if it
# isn't running yet).
set -eu

PASS_USER=email/protonmail-bridge/user
PASS_PW=email/protonmail-bridge/pass
HOST=127.0.0.1
PORT=1143

emit() {
  printf '%s\n' "$1"
  exit 0
}

# Cheap reachability probe — avoids a 30s python TLS timeout when the bridge
# is down (e.g. before it has finished unlocking on a fresh login).
ncat -z -w 1 "$HOST" "$PORT" 2>/dev/null ||
  emit '{"text":"󰵂","tooltip":"bridge unreachable","class":"error","alt":"error"}'

user=$(pass show "$PASS_USER" 2>/dev/null) ||
  emit '{"text":"󰵂","tooltip":"missing pass entry: '"$PASS_USER"'","class":"error","alt":"error"}'
pw=$(pass show "$PASS_PW" 2>/dev/null) ||
  emit '{"text":"󰵂","tooltip":"missing pass entry: '"$PASS_PW"'","class":"error","alt":"error"}'

n=$(
  PROTONMAIL_BRIDGE_USER="$user" PROTONMAIL_BRIDGE_PASS="$pw" \
    python3 - "$HOST" "$PORT" <<'PY' 2>/dev/null || true
import imaplib, os, ssl, sys
host, port = sys.argv[1], int(sys.argv[2])
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
try:
    m = imaplib.IMAP4(host, port)
    m.starttls(ssl_context=ctx)
    m.login(os.environ["PROTONMAIL_BRIDGE_USER"], os.environ["PROTONMAIL_BRIDGE_PASS"])
    typ, data = m.status("INBOX", "(UNSEEN)")
    m.logout()
    print(int(data[0].split(b"UNSEEN ")[1].rstrip(b")")))
except Exception:
    pass
PY
)

case "$n" in
  '') emit '{"text":"󰵂","tooltip":"IMAP query failed","class":"error","alt":"error"}' ;;
  0) emit '{"text":"󰇮","tooltip":"Inbox: no unread","class":"empty","alt":"empty"}' ;;
  *) emit "$(printf '{"text":"󰇮 %s","tooltip":"Inbox: %s unread","class":"unread","alt":"unread"}' "$n" "$n")" ;;
esac
