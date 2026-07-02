#!/usr/bin/env bash
# shellcheck shell=bash
# Shared helpers for just recipes.
# Sourced from justfile recipe bodies; not standalone.

_need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'error: %s not on PATH (install: %s)\n' "$1" "$2" >&2
    exit 1
  }
}

_find_shells() {
  find . -type f \
    \( -name '*.sh' \
    -o -path './dot_local/bin/executable_*' \
    -o -path './dot_config/sway/executable_*' \) \
    -not -path './.git/*' -not -path './.worktrees/*'
}

_find_by_ext() {
  find . -type f -name "*.$1" \
    -not -path './.git/*' -not -path './.worktrees/*'
}

_find_zsh() {
  find . -type f \
    \( -name 'dot_zshrc' -o -name 'dot_zshenv' -o -name 'dot_zprofile' \) \
    -not -path './.git/*' -not -path './.worktrees/*'
}

_is_zsh() {
  case "$(basename "$1")" in
    dot_zshrc | dot_zshenv | dot_zprofile | .zshrc | .zshenv | .zprofile) return 0 ;;
  esac
  return 1
}

_is_shellscript() {
  head -1 "$1" 2>/dev/null | grep -qE '^#!.*\b(ba)?sh\b'
}

_flatpak_install_declared() {
  [ -f meta/flatpak.txt ] || return 0
  flatpak remote-add --if-not-exists --user flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null
  flathub_ids=$(awk '!/^[[:space:]]*(#|$)/ && NF==1 {print $1}' meta/flatpak.txt)
  if [ -n "$flathub_ids" ]; then
    # shellcheck disable=SC2086
    flatpak install --user -y --noninteractive flathub $flathub_ids
  fi
  installed=$(flatpak list --user --app --columns=application 2>/dev/null || true)
  awk '!/^[[:space:]]*(#|$)/ && NF>=2 {print $1, $2}' meta/flatpak.txt |
    while read -r id url; do
      if printf '%s\n' "$installed" | grep -qxF "$id"; then
        continue
      fi
      echo ">>> downloading $id from $url"
      tmp=$(mktemp --suffix=.flatpak)
      curl -fsSL -o "$tmp" "$url"
      flatpak install --user -y --noninteractive "$tmp"
      rm -f "$tmp"
    done
}

_active_pacman_packages() {
  for file in meta/*.txt; do
    [ "$(basename "$file")" = "flatpak.txt" ] && continue
    pkgs=$(sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "$file")
    total=$(echo "$pkgs" | wc -l)
    installed=0
    for pkg in $pkgs; do
      pacman -Qi "$pkg" >/dev/null 2>&1 && installed=$((installed + 1))
    done
    if [ $((installed * 2)) -ge "$total" ]; then
      echo "$pkgs"
    fi
  done | sort -u
}

_undeclared_packages() {
  active=$(_active_pacman_packages)
  pacman -Qqe | while read -r pkg; do
    echo "$active" | grep -qxF "$pkg" || echo "$pkg"
  done
  if [ -f meta/flatpak.txt ]; then
    declared=$(awk '!/^[[:space:]]*(#|$)/ {print $1}' meta/flatpak.txt)
    flatpak list --user --app --columns=application 2>/dev/null | while read -r id; do
      [ -z "$id" ] && continue
      echo "$declared" | grep -qxF "$id" || echo "flatpak: $id"
    done
  fi
}
