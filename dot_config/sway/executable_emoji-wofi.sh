#!/bin/sh
# Bemoji picker backend: filter out skin-tone variants
# (U+1F3FB..U+1F3FF) before handing the emoji list to wofi.
set -eu

LC_ALL=C.UTF-8 grep -vP '[\x{1F3FB}-\x{1F3FF}]' \
  | wofi --dmenu --prompt Emoji --style "$HOME/.config/wofi/style.css"
