#!/usr/bin/env bash

# Set args and maintenance_run for one domain of a maintenance request.
# shellcheck disable=SC2034
_maintenance_select() {
  local scope=$1 domain=$2 role raw target
  shift 2
  role=$(_machine_role) || return 1
  args=()
  maintenance_run=false
  if [ "$scope" = host ]; then
    _require_host || return 1
    args=("$@")
    maintenance_run=true
    return
  fi
  for raw in "$@"; do
    case "$raw" in
      /etc/* | etc/*)
        [ "$role" = host ] || {
          echo 'error: /etc paths require the host role' >&2
          return 1
        }
        target=etc
        ;;
      */*) target=home ;;
      *)
        echo "error: expected a file path: $raw" >&2
        return 1
        ;;
    esac
    [ "$target" != "$domain" ] || args+=("$raw")
  done
  if [ ${#args[@]} -gt 0 ] || { [ $# -eq 0 ] && { [ "$domain" = home ] || [ "$role" = host ]; }; }; then
    maintenance_run=true
  fi
  return 0
}
