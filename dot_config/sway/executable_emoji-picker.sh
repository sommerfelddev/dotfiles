#!/usr/bin/env dash
# Bemoji wrapper: drop skin-tone variants (U+1F3FB..U+1F3FF) so the
# picker isn't cluttered with five copies of every people-emoji.
# Bemoji pipes its emoji list to whatever BEMOJI_PICKER_CMD evaluates
# to, so we point it at our small filter script.
set -eu

export BEMOJI_PICKER_CMD="$HOME/.config/sway/emoji-wofi.sh"
exec bemoji -tc "$@"
