#!/usr/bin/env bash
# shellcheck shell=bash
# Shared helpers for the fmt / check-fmt / lint just recipes.
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
