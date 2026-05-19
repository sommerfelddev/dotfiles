#!/bin/sh
# Sourced by every hook in this directory. Runs the per-repo hook of the
# same name from `<repo-top>/.githooks/` if it exists, then returns
# control so the calling user-level hook can do its own work after.
#
# Repos opt in by just dropping `.githooks/<hookname>` (executable) in
# the working tree — no per-repo `core.hooksPath` setting, no stubs.
# If the per-repo hook exits non-zero we abort with that status so git
# sees the failure.
#
# GIT_HOOK_DISPATCHED guards against re-entry: if some legacy repo has
# its own `.githooks/<hook>` that ends with `exec "$HOME/.config/..."`
# (the old pattern), we won't dispatch back into it a second time.

# shellcheck shell=sh
dispatch_repo_hook() {
  hookname=$1
  shift

  [ -n "${GIT_HOOK_DISPATCHED:-}" ] && return 0

  root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
  repo_hook="$root/.githooks/$hookname"
  [ -x "$repo_hook" ] || return 0

  GIT_HOOK_DISPATCHED=1 "$repo_hook" "$@"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    exit "$rc"
  fi
}
