#!/bin/sh
# Sourced by every hook in this directory. Runs the per-repo hook of
# the same name and then returns control so the calling user-level
# hook can do its own work after.
#
# Lookup order (first executable file wins):
#   1. `<git-dir>/hooks-local/<hookname>` — untracked per-clone override,
#      lives inside .git/ so it stays personal. Use this when you want
#      to replace a tracked .githooks/<name> on a shared repo without
#      affecting teammates. Create with e.g.:
#        $ mkdir -p "$(git rev-parse --git-dir)/hooks-local"
#        $ $EDITOR "$(git rev-parse --git-dir)/hooks-local/pre-commit"
#        $ chmod +x "$(git rev-parse --git-dir)/hooks-local/pre-commit"
#   2. `<repo-top>/.githooks/<hookname>` — tracked, the project's
#      shared hook. The intended default for opting a repo in.
#
# Either an empty file with exit 0 or no hook at all means "skip the
# project layer entirely"; the user-level hook still runs its own
# global logic afterwards.
#
# GIT_HOOK_DISPATCHED guards against re-entry: if some legacy repo has
# its own `.githooks/<hook>` that ends with `exec "$HOME/.config/..."`
# (the old stub pattern), we won't dispatch back into it a second time.

# shellcheck shell=sh
dispatch_repo_hook() {
  hookname=$1
  shift

  [ -n "${GIT_HOOK_DISPATCHED:-}" ] && return 0

  gitdir=$(git rev-parse --git-dir 2>/dev/null) || return 0
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0

  for candidate in "$gitdir/hooks-local/$hookname" "$root/.githooks/$hookname"; do
    if [ -x "$candidate" ]; then
      GIT_HOOK_DISPATCHED=1 "$candidate" "$@"
      rc=$?
      if [ "$rc" -ne 0 ]; then
        exit "$rc"
      fi
      return 0
    fi
  done
}
