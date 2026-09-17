#!/usr/bin/env sh
set -eu

if command -v gh >/dev/null 2>&1 && github_token=$(gh auth token --hostname github.com 2>/dev/null); then
  NIX_CONFIG="${NIX_CONFIG:-}
extra-access-tokens = github.com=$github_token"
  export NIX_CONFIG
  unset github_token
fi

exec "$@"
