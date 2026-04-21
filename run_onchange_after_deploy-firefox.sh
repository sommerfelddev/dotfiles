#!/bin/sh
# Deploy Firefox/LibreWolf hardening overrides and custom CSS
set -eu

SOURCE_DIR="$(chezmoi source-path)"

# Find LibreWolf profile directory (first profile with a default=1 marker)
PROFILES_DIR="$HOME/.librewolf"
if [ -d "$PROFILES_DIR" ]; then
    PROFILE=$(find "$PROFILES_DIR" -maxdepth 1 -mindepth 1 -type d -name '*.default-default' | head -1)
    if [ -z "$PROFILE" ]; then
        PROFILE=$(find "$PROFILES_DIR" -maxdepth 1 -mindepth 1 -type d | head -1)
    fi

    if [ -n "$PROFILE" ]; then
        cp "$SOURCE_DIR/firefox/user-overrides.js" "$PROFILE/user-overrides.js"
        mkdir -p "$PROFILE/chrome"
        cp "$SOURCE_DIR/firefox/chrome/userChrome.css" "$PROFILE/chrome/userChrome.css"
    fi
fi
