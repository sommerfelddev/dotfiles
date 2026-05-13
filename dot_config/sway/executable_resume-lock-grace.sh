#!/bin/sh
# resume-lock-grace: lock the screen if the user stays idle for $1
# (default 30) seconds after waking from suspend. Designed to be invoked
# from swayidle's `after-resume` so a quick wake-and-keep-using doesn't
# require typing the password, while a wake-and-walk-away still locks.
#
# Implementation: spawn a one-shot swayidle that locks once and exits.
# A watchdog kills it as soon as swaylock is detected, and a hard cap
# guarantees we never linger competing with the main swayidle.
set -eu

GRACE="${1:-30}"
LOCK_CMD='swaylock -f -e -c 282828'
HARD_CAP=$((GRACE * 4))

# If a lock is already up (e.g. main swayidle already fired), do nothing.
pgrep -x swaylock >/dev/null && exit 0

swayidle -w timeout "$GRACE" "$LOCK_CMD" >/dev/null 2>&1 &
PID=$!

elapsed=0
while [ "$elapsed" -lt "$HARD_CAP" ]; do
    if pgrep -x swaylock >/dev/null; then
        break
    fi
    if ! kill -0 "$PID" 2>/dev/null; then
        exit 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

kill "$PID" 2>/dev/null || true
wait 2>/dev/null || true
