#!/bin/sh
# Deploy system-level configs from etc/ and etc2/ to /etc/
# etc/ files can be symlinked; etc2/ files must be copied (tools that refuse symlinks)
set -eu

SOURCE_DIR="$(chezmoi source-path)"

# etc/ — symlink-friendly configs
for f in \
    modules-load.d/tcp_bbr.conf \
    pacman.d/hooks/orphans.hook \
    sysctl.d/99-sysctl.conf \
    systemd/system.conf.d/timeout.conf
do
    doas mkdir -p "/etc/$(dirname "$f")"
    doas cp "$SOURCE_DIR/etc/$f" "/etc/$f"
done

# etc2/ — must be real files (e.g. reflector refuses symlinks)
for f in \
    xdg/reflector/reflector.conf
do
    doas mkdir -p "/etc/$(dirname "$f")"
    doas cp "$SOURCE_DIR/etc2/$f" "/etc/$f"
done
