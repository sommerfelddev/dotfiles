#!/bin/sh
# Install a Node.js 24 (LTS) runtime under ~/.local/share/copilot-node/ for the
# exclusive use of copilot.lua / copilot-lsp inside neovim. System-wide nodejs
# (currently 26.x in Arch) is unaffected.
#
# Background: copilot-language-server is incompatible with Node 26's default
# fetch implementation. Multiple upstream issues, no fix yet:
#   https://github.com/zbirenbaum/copilot.lua/issues/695
#   https://github.com/github/copilot.vim/issues/282
#   https://github.com/github/copilot-language-server-release/issues/45
# Symptom: "HTTP 200 response does not appear to originate from GitHub".
# Workaround universally confirmed in those threads: use Node 24.
#
# chezmoi re-runs this only when the script content (and thus NODE_VERSION)
# changes. Bump NODE_VERSION + NODE_SHA256 below to upgrade.

set -eu

NODE_VERSION=24.15.0
# linux-x64 sha256 from https://nodejs.org/download/release/latest-v24.x/SHASUMS256.txt
NODE_SHA256=472655581fb851559730c48763e0c9d3bc25975c59d518003fc0849d3e4ba0f6
TARBALL="node-v${NODE_VERSION}-linux-x64.tar.xz"

DEST="${XDG_DATA_HOME:-$HOME/.local/share}/copilot-node"
STAMP="$DEST/.installed-${NODE_VERSION}"

if [ -x "$DEST/bin/node" ] && [ -f "$STAMP" ]; then
  exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl --fail --silent --show-error --location \
  --output "$tmp/$TARBALL" \
  "https://nodejs.org/download/release/v${NODE_VERSION}/${TARBALL}"

printf '%s  %s\n' "$NODE_SHA256" "$tmp/$TARBALL" | sha256sum -c -

tar -xJf "$tmp/$TARBALL" -C "$tmp"
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
mv "$tmp/node-v${NODE_VERSION}-linux-x64" "$DEST"
touch "$STAMP"
