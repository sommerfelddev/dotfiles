#!/bin/sh
# Bemoji wrapper: drop skin-tone variants (U+1F3FB..U+1F3FF) so the
# picker isn't cluttered with five copies of every people-emoji.
# Bemoji pipes its emoji list to $BEMOJI_PICKER_CMD on stdin.
set -eu

filter='LC_ALL=C.UTF-8 grep -vP "[\x{1F3FB}-\x{1F3FF}]"'
picker="wofi --dmenu --prompt Emoji --style $HOME/.config/wofi/style.css"

export BEMOJI_PICKER_CMD="sh -c '$filter | $picker'"
exec bemoji -tc "$@"
