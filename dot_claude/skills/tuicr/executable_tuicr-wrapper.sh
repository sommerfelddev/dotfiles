#!/usr/bin/env bash
# tuicr-wrapper: open tuicr in a zellij floating pane (or split) from a
# non-TTY context (e.g. claude-code, copilot CLI). Blocks on a FIFO until
# the spawned tuicr process exits, then emits any instructions written by
# tuicr's --output to stdout, wrapped in markers the agent recognises.
#
# Adapted from agavra/tuicr's tmux-based reference wrapper.
# See: dot_claude/skills/tuicr/SKILL.md
set -euo pipefail

TARGET_DIR="${1:-$PWD}"

if [ -z "${ZELLIJ:-}" ]; then
  cat <<'EOF' >&2
ERROR: not running inside a zellij session.

Restart the agent from inside a zellij session and try again:

    zellij
    # then, inside zellij:
    claude   # or: copilot
EOF
  exit 1
fi

if ! command -v tuicr >/dev/null 2>&1; then
  cat <<'EOF' >&2
ERROR: 'tuicr' is not installed.

Provisioned via nix; rebuild your profile:

    # host (Arch):
    just nix-switch

    # remote-dev VM:
    cd ~/.local/share/dotfiles/remote-dev
    home-manager switch --impure --flake .#vm -b backup
EOF
  exit 1
fi

if ! git -C "$TARGET_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: '$TARGET_DIR' is not a git repository" >&2
  exit 1
fi

# Refuse to nest if another tuicr is already running (zellij has no
# tmux-style 'list-panes | grep'; pgrep is the closest cross-pane probe).
if pgrep -x tuicr >/dev/null 2>&1; then
  echo "ERROR: tuicr is already running in this session" >&2
  exit 1
fi

# Per-invocation tmpdir holds:
#   done   - FIFO; child writes one byte on exit, parent blocks read
#   output - tuicr --output target (instructions to relay back)
TMPDIR_TUICR="$(mktemp -d -t tuicr.XXXXXX)"
DONE_FIFO="$TMPDIR_TUICR/done"
OUTPUT_FILE="$TMPDIR_TUICR/output"
trap 'rm -rf "$TMPDIR_TUICR"' EXIT
mkfifo "$DONE_FIFO"
: >"$OUTPUT_FILE"

PANE_MODE="${TUICR_PANE_MODE:-floating}"
SPLIT_DIR="${TUICR_SPLIT_DIR:-down}"

# Child command: cd into the repo, run tuicr exporting instructions, then
# signal the parent regardless of exit status.
CHILD_CMD="cd $(printf %q "$TARGET_DIR") && \
  tuicr --output $(printf %q "$OUTPUT_FILE"); \
  printf done > $(printf %q "$DONE_FIFO")"

case "$PANE_MODE" in
  floating)
    zellij action new-pane --floating \
      --cwd "$TARGET_DIR" \
      -- bash -lc "$CHILD_CMD" >/dev/null
    ;;
  split)
    zellij action new-pane \
      --direction "$SPLIT_DIR" \
      --cwd "$TARGET_DIR" \
      -- bash -lc "$CHILD_CMD" >/dev/null
    ;;
  *)
    echo "ERROR: invalid TUICR_PANE_MODE='$PANE_MODE' (expected floating|split)" >&2
    exit 1
    ;;
esac

# Block until the child writes its sentinel.
read -r _ <"$DONE_FIFO"

# Relay instructions back to the agent if tuicr wrote any.
if [ -s "$OUTPUT_FILE" ]; then
  echo "=== TUICR INSTRUCTIONS ==="
  cat "$OUTPUT_FILE"
  echo
  echo "=== END TUICR INSTRUCTIONS ==="
else
  echo "tuicr exited with no instructions" >&2
fi
