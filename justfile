# Show available recipes (default)
default:
    @just --list

# ═══════════════════════════════════════════════════════════════════
# Setup
# ═══════════════════════════════════════════════════════════════════

# First-time machine setup: regenerate chezmoi config, install git hooks, deploy dotfiles, install base packages, enable curated units
init: _chezmoi-init _install-hooks apply (pkg-apply "base") unit-apply

# ═══════════════════════════════════════════════════════════════════
# Day-to-day
# ═══════════════════════════════════════════════════════════════════

# Reconcile everything: deploy dotfiles + /etc, top up packages, enable curated units
sync: apply pkg-fix unit-apply

# Deploy dotfiles AND /etc atomically (chezmoi apply; /etc handled by onchange template)
apply:
    chezmoi apply -S .

# ═══════════════════════════════════════════════════════════════════
# Updates
# ═══════════════════════════════════════════════════════════════════

# Update everything: system packages, Neovim plugins, Mason tools, flatpaks
update: pkg-update nvim-update flatpak-update

# Upgrade all system + AUR packages
pkg-update:
    paru -Syu

# Update all user-scope flatpaks (Flathub apps + URL bundles when their version changes)
flatpak-update:
    #!/bin/sh
    set -eu
    flatpak update --user -y --noninteractive
    [ -f meta/flatpak.txt ] || exit 0
    awk '!/^[[:space:]]*(#|$)/ && NF>=2 {print $1, $2}' meta/flatpak.txt \
        | while read -r id url; do
            url_ver=$(echo "$url" | grep -oE 'v?[0-9]+(\.[0-9]+)+' | head -1 | sed 's/^v//')
            installed_ver=$(flatpak info --user "$id" 2>/dev/null \
                | awk -F: '/^[[:space:]]*Version:/ {gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2); print $2; exit}')
            if [ -n "$url_ver" ] && [ "$url_ver" = "$installed_ver" ]; then
                continue
            fi
            echo ">>> updating $id from $url"
            tmp=$(mktemp --suffix=.flatpak)
            curl -fsSL -o "$tmp" "$url"
            flatpak install --user -y --noninteractive --reinstall "$tmp"
            rm -f "$tmp"
        done

# Update Neovim plugins (vim.pack) and Mason tools in a headless session
nvim-update:
    nvim --headless '+lua require("config.update").run()'

# Re-add changes from live files back into the repo; pass a path to target one, or omit for all
re-add *paths:
    #!/usr/bin/env bash
    set -eo pipefail
    args=({{ paths }})
    if [ ${#args[@]} -eq 0 ]; then
        just dotfiles-re-add
        just etc-re-add
        exit 0
    fi
    for raw in "${args[@]}"; do
        case "$raw" in
            /etc/*|etc/*) just etc-re-add "$raw" ;;
            */*)          just dotfiles-re-add "$raw" ;;
            *)
                echo "error: re-add needs a path (got bare word: $raw)" >&2
                exit 1
                ;;
        esac
    done

# Format code; pass a path to format a single file, or omit to format everything
fmt *target:
    #!/usr/bin/env bash
    set -eo pipefail
    source "{{ justfile_directory() }}/just-lib.sh"

    _fmt_lua()      { _need stylua stylua;        stylua "$@"; }
    _fmt_sh()       { _need shfmt shfmt;          shfmt -w -i 2 -ci -s "$@"; }
    _fmt_py()       { _need ruff ruff;            ruff format "$@"; }
    _fmt_toml()     { _need taplo taplo-cli;      taplo format "$@"; }
    _fmt_just()     { just --unstable --fmt; }
    _fmt_prettier() { _need prettier prettier;    prettier --write "$@"; }

    target='{{ target }}'

    if [ -z "$target" ]; then
      mapfile -t files < <(_find_by_ext lua)
      [ ${#files[@]} -gt 0 ] && _fmt_lua "${files[@]}"

      mapfile -t files < <(_find_shells)
      [ ${#files[@]} -gt 0 ] && _fmt_sh "${files[@]}"

      mapfile -t files < <(_find_by_ext py)
      [ ${#files[@]} -gt 0 ] && _fmt_py "${files[@]}"

      mapfile -t files < <(_find_by_ext toml)
      [ ${#files[@]} -gt 0 ] && _fmt_toml "${files[@]}"

      _fmt_just

      _fmt_prettier --ignore-unknown --log-level=warn \
        '**/*.md' '**/*.json' '**/*.jsonc' \
        '**/*.yaml' '**/*.yml' '**/*.css'
      exit 0
    fi

    [ -f "$target" ] || { echo "error: no such file: $target" >&2; exit 1; }

    if _is_zsh "$target"; then
      echo "skip: $target (no formatter for zsh)" >&2; exit 0
    fi
    case "$(basename "$target")" in
      justfile) _fmt_just; exit 0 ;;
    esac
    case "$target" in
      *.lua)                                   _fmt_lua  "$target" ;;
      *.sh)                                    _fmt_sh   "$target" ;;
      *.py)                                    _fmt_py   "$target" ;;
      *.toml)                                  _fmt_toml "$target" ;;
      *.md|*.json|*.jsonc|*.yaml|*.yml|*.css)  _fmt_prettier "$target" ;;
      *)
        if _is_shellscript "$target"; then
          _fmt_sh "$target"
        else
          echo "error: no formatter for: $target" >&2; exit 1
        fi
        ;;
    esac

# Check formatting without writing; pass a path to check a single file, or omit to check everything
check-fmt *target:
    #!/usr/bin/env bash
    set -eo pipefail
    source "{{ justfile_directory() }}/just-lib.sh"

    _chk_lua()      { _need stylua stylua;        stylua --check "$@"; }
    _chk_sh()       { _need shfmt shfmt;          shfmt -d -i 2 -ci -s "$@"; }
    _chk_py()       { _need ruff ruff;            ruff format --check "$@"; }
    _chk_toml()     { _need taplo taplo-cli;      taplo format --check "$@"; }
    _chk_just()     { just --unstable --fmt --check; }
    _chk_prettier() { _need prettier prettier;    prettier --check "$@"; }

    target='{{ target }}'
    rc=0

    if [ -z "$target" ]; then
      mapfile -t files < <(_find_by_ext lua)
      [ ${#files[@]} -gt 0 ] && { _chk_lua "${files[@]}" || rc=$?; }

      mapfile -t files < <(_find_shells)
      [ ${#files[@]} -gt 0 ] && { _chk_sh "${files[@]}" || rc=$?; }

      mapfile -t files < <(_find_by_ext py)
      [ ${#files[@]} -gt 0 ] && { _chk_py "${files[@]}" || rc=$?; }

      mapfile -t files < <(_find_by_ext toml)
      [ ${#files[@]} -gt 0 ] && { _chk_toml "${files[@]}" || rc=$?; }

      _chk_just || rc=$?

      _chk_prettier --ignore-unknown --log-level=warn \
        '**/*.md' '**/*.json' '**/*.jsonc' \
        '**/*.yaml' '**/*.yml' '**/*.css' || rc=$?
      exit $rc
    fi

    [ -f "$target" ] || { echo "error: no such file: $target" >&2; exit 1; }

    if _is_zsh "$target"; then
      echo "skip: $target (no formatter for zsh)" >&2; exit 0
    fi
    case "$(basename "$target")" in
      justfile) _chk_just; exit $? ;;
    esac
    case "$target" in
      *.lua)                                   _chk_lua  "$target" ;;
      *.sh)                                    _chk_sh   "$target" ;;
      *.py)                                    _chk_py   "$target" ;;
      *.toml)                                  _chk_toml "$target" ;;
      *.md|*.json|*.jsonc|*.yaml|*.yml|*.css)  _chk_prettier "$target" ;;
      *)
        if _is_shellscript "$target"; then
          _chk_sh "$target"
        else
          echo "error: no formatter for: $target" >&2; exit 1
        fi
        ;;
    esac

# Code quality gate: check formatting + lint; pass a path to check a single file, or omit for whole repo
check *target:
    @just check-fmt {{ target }}
    @just lint {{ target }}

# Lint code; pass a path to lint a single file, or omit to lint everything
lint *target:
    #!/usr/bin/env bash
    set -eo pipefail
    source "{{ justfile_directory() }}/just-lib.sh"

    _lint_lua()      { _need selene selene;         selene "$@"; }
    _lint_sh()       { _need shellcheck shellcheck; shellcheck "$@"; }
    _lint_zsh()      { _need shellcheck shellcheck; shellcheck --shell=bash "$@"; }
    _lint_py()       { _need ruff ruff;             ruff check "$@"; }
    _lint_toml()     { _need taplo taplo-cli;       taplo lint "$@"; }

    target='{{ target }}'
    rc=0

    if [ -z "$target" ]; then
      mapfile -t files < <(_find_by_ext lua)
      [ ${#files[@]} -gt 0 ] && { _lint_lua "${files[@]}" || rc=$?; }

      mapfile -t files < <(_find_shells)
      [ ${#files[@]} -gt 0 ] && { _lint_sh "${files[@]}" || rc=$?; }

      mapfile -t files < <(_find_zsh)
      [ ${#files[@]} -gt 0 ] && { _lint_zsh "${files[@]}" || rc=$?; }

      mapfile -t files < <(_find_by_ext py)
      [ ${#files[@]} -gt 0 ] && { _lint_py "${files[@]}" || rc=$?; }

      mapfile -t files < <(_find_by_ext toml)
      [ ${#files[@]} -gt 0 ] && { _lint_toml "${files[@]}" || rc=$?; }

      exit $rc
    fi

    [ -f "$target" ] || { echo "error: no such file: $target" >&2; exit 1; }

    if _is_zsh "$target"; then _lint_zsh "$target"; exit $?; fi
    case "$(basename "$target")" in
      justfile) echo "skip: $target (no linter; use check-fmt)" >&2; exit 0 ;;
    esac
    case "$target" in
      *.lua)                                   _lint_lua  "$target" ;;
      *.sh)                                    _lint_sh   "$target" ;;
      *.py)                                    _lint_py   "$target" ;;
      *.toml)                                  _lint_toml "$target" ;;
      *.md|*.json|*.jsonc|*.yaml|*.yml|*.css)  echo "skip: $target (no linter; use check-fmt)" >&2; exit 0 ;;
      *)
        if _is_shellscript "$target"; then
          _lint_sh "$target"
        else
          echo "error: no linter for: $target" >&2; exit 1
        fi
        ;;
    esac

# ═══════════════════════════════════════════════════════════════════
# Inspection
# ═══════════════════════════════════════════════════════════════════

# Check that all tools needed by 'just check' are installed
doctor:
    #!/usr/bin/env bash
    rc=0
    for tool in stylua selene shfmt shellcheck ruff taplo prettier just; do
        if command -v "$tool" >/dev/null 2>&1; then
            printf '  ✓ %s (%s)\n' "$tool" "$(command -v "$tool")"
        else
            printf '  ✗ %s  missing\n' "$tool"
            rc=1
        fi
    done
    exit $rc

# Show drift across all four domains (dotfiles, /etc, packages, units)
status: dotfiles-status etc-status pkg-status unit-status

# ═══════════════════════════════════════════════════════════════════
# Top-level dispatchers
#
# Argument-shape rules (first match wins):
#   1. contains '/'                                 -> path
#        prefix /etc or etc/                        -> etc domain
#        otherwise                                  -> dotfiles domain
#   2. 2+ args AND any rest arg ends with a unit    -> unit domain
#      extension (.service/.timer/.socket/.mount/
#      .target/.path)
#   3. otherwise (bare word, 2+ args)               -> pkg domain
#
# For 2-arg verbs (add, forget): the 2nd arg is the discriminator.
# ═══════════════════════════════════════════════════════════════════

# Add one or more paths (dotfile/etc), units, or packages (GROUP + names) to the repo
add +args:
    #!/usr/bin/env bash
    set -eo pipefail
    args=({{ args }})
    first=${args[0]}
    case "$first" in
        /etc/*|etc/*) just etc-add "${args[@]}" ; exit 0 ;;
        */*)          just dotfiles-add "${args[@]}" ; exit 0 ;;
    esac
    # Units: any arg looks like a unit (no GROUP prefix; scope is inferred).
    for a in "${args[@]}"; do
        case "$a" in
            *.service|*.timer|*.socket|*.mount|*.target|*.path)
                just unit-add "${args[@]}"; exit 0 ;;
        esac
    done
    if [ ${#args[@]} -lt 2 ]; then
        echo "error: add needs either a path, a unit name, or a GROUP plus one or more pkg names" >&2
        echo "       (got single bare word: $first)" >&2
        exit 1
    fi
    just pkg-add "${args[@]}"

# Remove one or more paths, units, or packages (GROUP + names) from tracking (leaves live state alone)
forget +args:
    #!/usr/bin/env bash
    set -eo pipefail
    args=({{ args }})
    first=${args[0]}
    case "$first" in
        /etc/*|etc/*) just etc-forget "${args[@]}" ; exit 0 ;;
        */*)          just dotfiles-forget "${args[@]}" ; exit 0 ;;
    esac
    for a in "${args[@]}"; do
        case "$a" in
            *.service|*.timer|*.socket|*.mount|*.target|*.path)
                just unit-forget "${args[@]}"; exit 0 ;;
        esac
    done
    if [ ${#args[@]} -lt 2 ]; then
        echo "error: forget needs either a path, a unit name, or a GROUP plus one or more pkg names" >&2
        echo "       (got single bare word: $first)" >&2
        exit 1
    fi
    just pkg-forget "${args[@]}"

# Show dotfile + /etc diffs; pass a path to limit to a single file
diff *paths:
    #!/usr/bin/env bash
    set -eo pipefail
    args=({{ paths }})
    if [ ${#args[@]} -eq 0 ]; then
        just dotfiles-diff
        just etc-diff
        exit 0
    fi
    for raw in "${args[@]}"; do
        case "$raw" in
            /etc/*|etc/*) just etc-diff "$raw" ;;
            */*)          just dotfiles-diff "$raw" ;;
            *)
                echo "error: diff needs a path (got bare word: $raw)" >&2
                exit 1
                ;;
        esac
    done

# 3-way merge dotfile or /etc conflicts; pass a path for one file, or omit to merge all
merge *paths:
    #!/usr/bin/env bash
    set -eo pipefail
    args=({{ paths }})
    if [ ${#args[@]} -eq 0 ]; then
        just dotfiles-merge
        just etc-merge
        exit 0
    fi
    for raw in "${args[@]}"; do
        case "$raw" in
            /etc/*|etc/*) just etc-merge "$raw" ;;
            */*)          just dotfiles-merge "$raw" ;;
            *)
                echo "error: merge needs a path (got bare word: $raw)" >&2
                exit 1
                ;;
        esac
    done

# ═══════════════════════════════════════════════════════════════════
# Dotfiles domain (chezmoi-backed)
# ═══════════════════════════════════════════════════════════════════

# Adopt one or more dotfile paths into the chezmoi source state
dotfiles-add +paths:
    chezmoi add -S . {{ paths }}

# Remove one or more dotfile paths from the chezmoi source state (leaves $HOME alone)
dotfiles-forget +paths:
    chezmoi forget -S . {{ paths }}

# Re-add changes from live dotfiles back into the repo; pass paths to target specific files
dotfiles-re-add *paths:
    chezmoi re-add -S . {{ paths }}

# Show dotfile diffs; pass a path to limit to a single file
dotfiles-diff *paths:
    chezmoi diff -S . {{ paths }}

# 3-way merge dotfile conflicts; pass a path for one file, or omit to merge all
dotfiles-merge *paths:
    #!/bin/sh
    if [ -n '{{ paths }}' ]; then
        chezmoi merge -S . {{ paths }}
    else
        chezmoi merge-all -S .
    fi

# Show dotfile drift (wraps 'chezmoi status')
dotfiles-status:
    #!/bin/sh
    echo "=== Dotfile drift ==="
    chezmoi status -S . || true

# ═══════════════════════════════════════════════════════════════════
# Units domain (systemd)
# ═══════════════════════════════════════════════════════════════════
# systemd-units domain
# ═══════════════════════════════════════════════════════════════════
#
# Two flat lists: systemd-units/system.txt (enabled via `sudo systemctl`)
# and systemd-units/user.txt (enabled via `systemctl --user`). No groups.
# unit-add / unit-forget infer scope by probing the unit's existence with
# systemctl [--user] cat — caller doesn't pass a scope.

# List curated systemd units with their enabled/active state
unit-list:
    #!/bin/sh
    _render() {
        scope=$1 file=$2
        sctl="systemctl"; [ "$scope" = user ] && sctl="systemctl --user"
        echo "=== ${scope} ==="
        sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "$file" | while read -r u; do
            en=$($sctl is-enabled "$u" 2>/dev/null); en=${en:-unknown}
            ac=$($sctl is-active  "$u" 2>/dev/null); ac=${ac:-unknown}
            case "$en" in
                enabled|enabled-runtime|static|alias|indirect|generated) c_en=32 ;;
                disabled|masked|not-found)                               c_en=31 ;;
                *)                                                       c_en=33 ;;
            esac
            case "$ac" in
                active)                       c_ac=32 ;;
                inactive|failed)              c_ac=31 ;;
                *)                            c_ac=33 ;;
            esac
            printf '  %-34s \033[%sm%-10s\033[0m \033[%sm%s\033[0m\n' "$u" "$c_en" "$en" "$c_ac" "$ac"
        done
    }
    for scope in system user; do
        file="systemd-units/${scope}.txt"
        [ -f "$file" ] || continue
        _render "$scope" "$file"
    done

# Enable all curated systemd units (idempotent, soft-fail per unit); walks system + user lists
unit-apply:
    #!/bin/sh
    if [ -f systemd-units/system.txt ]; then
        sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' systemd-units/system.txt | while read -r u; do
            sudo systemctl enable --now "$u" \
                || echo "  warn: could not enable $u (system)" >&2
        done
    fi
    if [ -f systemd-units/user.txt ]; then
        sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' systemd-units/user.txt | while read -r u; do
            systemctl --user enable --now "$u" \
                || echo "  warn: could not enable $u (user)" >&2
        done
    fi

# Show drift between curated units and actually-enabled systemd units (system + user)
unit-status:
    #!/bin/sh
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    _drift() {
        scope=$1 label=$2
        sctl="systemctl"; [ "$scope" = user ] && sctl="systemctl --user"
        echo "=== ${label} drift ==="
        if [ -f "systemd-units/${scope}.txt" ]; then
            sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "systemd-units/${scope}.txt" | sort -u > "$tmp/curated"
        else
            : > "$tmp/curated"
        fi
        if [ -f "systemd-units/${scope}.ignore" ]; then
            sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "systemd-units/${scope}.ignore" | sort -u > "$tmp/ignore"
        else
            : > "$tmp/ignore"
        fi
        # Curated units missing from the system: is-enabled correctly handles
        # instantiated template units (list-unit-files does not show those).
        while read -r u; do
            [ -z "$u" ] && continue
            state=$($sctl is-enabled "$u" 2>/dev/null || true)
            case "$state" in
                enabled|enabled-runtime|alias|static|indirect|generated) ;;
                *) echo "  not-enabled: $u" ;;
            esac
        done < "$tmp/curated"
        # Enabled unit files not in curated (minus ignore list).
        $sctl list-unit-files --state=enabled --no-legend 2>/dev/null \
            | awk '{print $1}' | grep -vE '@\.' | sort -u > "$tmp/enabled"
        comm -13 "$tmp/curated" "$tmp/enabled" | comm -23 - "$tmp/ignore" | sed 's/^/  uncurated:   /'
    }
    _drift system "System unit"
    _drift user   "User unit"

# Append one or more units to the curated list and enable them; scope is

# inferred by probing `systemctl [--user] cat <unit>` (system wins on tie).
unit-add +units:
    #!/bin/sh
    set -eu
    _scope() {
        u=$1
        sys=0 usr=0
        systemctl cat "$u"        >/dev/null 2>&1 && sys=1
        systemctl --user cat "$u" >/dev/null 2>&1 && usr=1
        if   [ "$sys" = 1 ]; then echo system
        elif [ "$usr" = 1 ]; then echo user
        else                      echo unknown
        fi
    }
    for u in {{ units }}; do
        scope=$(_scope "$u")
        if [ "$scope" = unknown ]; then
            echo "error: $u not found at either scope (install the package first)" >&2
            exit 1
        fi
        file="systemd-units/${scope}.txt"
        if grep -qxF "$u" "$file"; then
            echo "$u already in ${scope}"
        else
            echo "$u" >> "$file"
            echo "added $u to ${scope}"
        fi
        if [ "$scope" = user ]; then
            systemctl --user enable --now "$u" \
                || echo "  warn: could not enable $u (user)" >&2
        else
            sudo systemctl enable --now "$u" \
                || echo "  warn: could not enable $u (system)" >&2
        fi
    done

# Remove one or more units from the curated list and disable them; scope is

# inferred from which list currently contains the unit.
unit-forget +units:
    #!/bin/sh
    set -eu
    for u in {{ units }}; do
        scope=
        for s in system user; do
            if [ -f "systemd-units/${s}.txt" ] && grep -qxF "$u" "systemd-units/${s}.txt"; then
                scope=$s; break
            fi
        done
        if [ -z "$scope" ]; then
            echo "$u not in any curated list" >&2
            continue
        fi
        file="systemd-units/${scope}.txt"
        sed -i "/^$(printf '%s' "$u" | sed 's/[]\/$*.^[]/\\&/g')\$/d" "$file"
        echo "removed $u from ${scope}"
        if [ "$scope" = user ]; then
            systemctl --user disable --now "$u" \
                || echo "  warn: could not disable $u (user)" >&2
        else
            sudo systemctl disable --now "$u" \
                || echo "  warn: could not disable $u (system)" >&2
        fi
    done

# ═══════════════════════════════════════════════════════════════════
# /etc domain
# ═══════════════════════════════════════════════════════════════════

# Show /etc drift: repo-tracked files that differ from or are missing on the host
etc-status:
    #!/usr/bin/env bash
    set -eo pipefail
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    echo "=== /etc drift ==="
    while IFS= read -r repo; do
        live=/etc/${repo#etc/}; live=${live%.tmpl}
        if [ "${repo%.tmpl}" != "$repo" ]; then
            src=$tmp/rendered
            chezmoi execute-template <"$repo" >"$src"
        else
            src=$repo
        fi
        if [ -r "$live" ]; then
            cmp -s "$src" "$live" || echo "  modified: $live"
        elif sudo test -f "$live" 2>/dev/null; then
            sudo cat "$live" | cmp -s "$src" - || echo "  modified: $live"
        else
            echo "  missing:  $live"
        fi
    done < <(find etc -type f ! -name .ignore | sort)

# Diff repo-managed etc/<path> against live /etc/<path> (all managed files if no args)
etc-diff *paths:
    #!/usr/bin/env bash
    set -eo pipefail
    args=({{ paths }})
    if [ ${#args[@]} -eq 0 ]; then
        mapfile -t args < <(find etc -type f ! -name .ignore | sort)
    fi
    for raw in "${args[@]}"; do
        case "$raw" in
            *..*|*/./*|./*|../*) echo "error: unsafe path: $raw" >&2; exit 1 ;;
        esac
        p=${raw#/}; p=${p#etc/}
        live=/etc/${p%.tmpl}
        repo=etc/$p
        if [ ! -f "$repo" ]; then
            if [ -f "$repo.tmpl" ]; then
                repo=$repo.tmpl
                live=/etc/$p
            else
                echo "skip: $live (not a regular file in etc/)" >&2; continue
            fi
        fi
        # Render .tmpl sources so the diff reflects what would actually deploy.
        if [ "${repo%.tmpl}" != "$repo" ]; then
            rendered=$(mktemp)
            chezmoi execute-template <"$repo" >"$rendered"
            repo_for_diff=$rendered
        else
            repo_for_diff=$repo
            rendered=
        fi
        # Fast path for world-readable files; sudo fallback only when needed (e.g. /etc/sudo.conf 0600).
        if [ -r "$live" ]; then
            diff -u --label "$live" --label "$repo" "$live" "$repo_for_diff" || true
        elif sudo test -f "$live"; then
            diff -u --label "$live" --label "$repo" <(sudo cat "$live") "$repo_for_diff" || true
        else
            echo "skip: $live (missing or not a regular file on host)" >&2
        fi
        [ -n "$rendered" ] && rm -f "$rendered"
    done

# Diff live /etc/<path> against pristine pacman version (defaults to all repo-managed files)
etc-upstream-diff *paths:
    #!/usr/bin/env bash
    set -eo pipefail
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

    # Fetch the cache archive for a /etc/<path>'s owning package at its installed version.
    # Prints cache path on stdout. Exit 2 = unowned, 1 = cache unavailable for installed version.
    pristine() {
        local path=$1
        local pkg ver arch cache
        pkg=$(pacman -Qoq "$path" 2>/dev/null) || return 2
        ver=$(pacman -Q "$pkg" | awk '{print $2}')
        arch=$(pacman -Qi "$pkg" | awk -F': *' '/^Architecture/{print $2; exit}')
        for ext in zst xz; do
            cache="/var/cache/pacman/pkg/${pkg}-${ver}-${arch}.pkg.tar.${ext}"
            [ -f "$cache" ] && { echo "$cache"; return 0; }
        done
        echo "  fetching $pkg from mirror..." >&2
        sudo pacman -Sw --noconfirm "$pkg" >/dev/null || true
        for ext in zst xz; do
            cache="/var/cache/pacman/pkg/${pkg}-${ver}-${arch}.pkg.tar.${ext}"
            [ -f "$cache" ] && { echo "$cache"; return 0; }
        done
        echo "  error: no cache for ${pkg}-${ver}; mirror may have moved past installed version (try Arch Linux Archive)" >&2
        return 1
    }

    args=({{ paths }})
    explicit=1
    if [ ${#args[@]} -eq 0 ]; then
        explicit=0
        mapfile -t args < <(find etc -type f ! -name .ignore | sed 's|^etc/|/etc/|' | sort)
    fi

    for raw in "${args[@]}"; do
        case "$raw" in
            *..*|*/./*) echo "error: unsafe path: $raw" >&2; exit 1 ;;
        esac
        # Accept both /etc/foo and etc/foo; normalize to /etc/foo
        p=${raw#/}; p=${p#etc/}
        path=/etc/$p
        if [ -r "$path" ]; then
            live_reader=(cat "$path")
        elif sudo test -f "$path"; then
            live_reader=(sudo cat "$path")
        else
            [ "$explicit" = 1 ] && { echo "error: $path missing or unreadable" >&2; exit 1; }
            echo "skip: $path (missing or unreadable)" >&2; continue
        fi
        if ! cache=$(pristine "$path"); then
            [ "$explicit" = 1 ] && { echo "error: cannot obtain pristine for $path" >&2; exit 1; }
            continue
        fi
        out="$tmp/pristine"
        if ! bsdtar -xOf "$cache" "${path#/}" > "$out" 2>/dev/null; then
            echo "skip: $path (not present in package archive)" >&2
            continue
        fi
        diff -u --label "$path (pristine)" --label "$path (live)" "$out" <("${live_reader[@]}") || true
    done

# 3-way merge tracked /etc files against their live /etc counterparts (edit repo side)
etc-merge *paths:
    #!/usr/bin/env bash
    set -eo pipefail
    args=({{ paths }})
    if [ ${#args[@]} -eq 0 ]; then
        mapfile -t args < <(find etc -type f ! -name .ignore | sort)
    fi
    editor=${VISUAL:-${EDITOR:-vi}}
    merged=0
    for raw in "${args[@]}"; do
        case "$raw" in
            *..*|*/./*|./*|../*) echo "error: unsafe path: $raw" >&2; exit 1 ;;
        esac
        p=${raw#/}; p=${p#etc/}
        live=/etc/$p
        repo=etc/$p
        [ -f "$repo" ] || { echo "skip: etc/$p not tracked" >&2; continue; }
        # Prepare a readable copy of live (falling back to sudo cat for restricted files).
        tmp=$(mktemp)
        trap 'rm -f "$tmp"' EXIT
        if [ -r "$live" ]; then
            cat -- "$live" > "$tmp"
        elif sudo test -f "$live"; then
            sudo cat -- "$live" > "$tmp"
        else
            echo "skip: $live (missing or unreadable)" >&2
            rm -f "$tmp"
            continue
        fi
        if cmp -s "$repo" "$tmp"; then
            rm -f "$tmp"
            continue
        fi
        # Use vim -d (vimdiff) for vim/neovim; otherwise open both and let the editor sort it.
        case "$(basename "$editor")" in
            vi|vim|nvim) "$editor" -d "$repo" "$tmp" ;;
            *)           "$editor" "$repo" "$tmp" ;;
        esac
        rm -f "$tmp"
        merged=$((merged + 1))
    done
    [ "$merged" -eq 0 ] && echo "no drift to merge"

# Copy one or more /etc/<path> regular files into the repo's etc/ tree
etc-add +paths:
    #!/usr/bin/env bash
    set -eo pipefail
    for path in {{ paths }}; do
        case "$path" in
            *..*|*/./*) echo "error: unsafe path: $path" >&2; exit 1 ;;
        esac
        [[ "$path" = /etc/* ]] || { echo "error: $path not under /etc" >&2; exit 1; }
        [ -f "$path" ] || { echo "error: $path is not a regular file (symlinks/dirs not supported)" >&2; exit 1; }
        dest="etc/${path#/etc/}"
        mkdir -p "$(dirname "$dest")"
        sudo cp -a "$path" "$dest"
        sudo chown "$USER:$USER" "$dest"
        echo "added: $path -> $dest"
    done
    echo
    echo "Run 'chezmoi apply' to sync (no-op content-wise, refreshes deploy hash)."

# Re-add changes from live /etc back into the repo (no args = all tracked files)
etc-re-add *paths:
    #!/usr/bin/env bash
    set -eo pipefail
    # Build target list: explicit paths, or every tracked repo file.
    targets=()
    if [ -n "{{ paths }}" ]; then
        for raw in {{ paths }}; do
            case "$raw" in
                *..*|*/./*|./*|../*) echo "error: unsafe path: $raw" >&2; exit 1 ;;
            esac
            p=${raw#/}; p=${p#etc/}
            [ -f "etc/$p" ] || { echo "error: etc/$p is not tracked; use 'just etc-add' to adopt" >&2; exit 1; }
            targets+=("$p")
        done
    else
        while IFS= read -r f; do
            targets+=("${f#etc/}")
        done < <(find etc -type f ! -name .ignore | sort)
    fi
    changed=0
    for p in "${targets[@]}"; do
        # Template sources can't be reverse-rendered; skip with a note.
        case "$p" in
            *.tmpl)
                echo "  skip .tmpl: etc/$p (edit the template manually)"
                continue
                ;;
        esac
        live=/etc/$p
        repo=etc/$p
        [ -e "$live" ] || { echo "  missing live: $live (skipped)"; continue; }
        [ -f "$live" ] || { echo "  not a regular file: $live (skipped)"; continue; }
        if [ -r "$live" ]; then
            cat -- "$live" > "$repo.tmp"
        else
            sudo cat -- "$live" > "$repo.tmp"
        fi
        if cmp -s "$repo" "$repo.tmp"; then
            rm -f "$repo.tmp"
        else
            mv "$repo.tmp" "$repo"
            echo "re-added: $live -> $repo"
            changed=$((changed + 1))
        fi
    done
    if [ $changed -eq 0 ]; then
        echo "no changes"
    else
        just apply
    fi

# Remove one or more files from the repo's etc/ tree (leaves live /etc untouched)
etc-forget +paths:
    #!/usr/bin/env bash
    set -eo pipefail
    for raw in {{ paths }}; do
        case "$raw" in
            *..*|*/./*|./*|../*) echo "error: unsafe path: $raw" >&2; exit 1 ;;
        esac
        p=${raw#/}; p=${p#etc/}
        repo=etc/$p
        [ -f "$repo" ] || { echo "error: $repo is not managed in the repo" >&2; exit 1; }
        rm -- "$repo"
        # Tidy empty parent dirs inside etc/ without walking out of it
        parent=$(dirname "$repo")
        while [ "$parent" != "etc" ] && [ "$parent" != "." ]; do
            rmdir -- "$parent" 2>/dev/null || break
            parent=$(dirname "$parent")
        done
        echo "removed: $repo  (/etc/$p left untouched)"
    done
    just apply

# Reset repo-managed etc/<path> to pristine pacman contents and deploy
etc-reset +paths:
    #!/usr/bin/env bash
    set -eo pipefail
    for raw in {{ paths }}; do
        case "$raw" in
            *..*|*/./*|./*|../*) echo "error: unsafe path: $raw" >&2; exit 1 ;;
        esac
        p=${raw#/}; p=${p#etc/}
        live=/etc/$p
        repo=etc/$p
        [ -f "$repo" ] || { echo "error: $repo is not managed in the repo" >&2; exit 1; }
        pkg=$(pacman -Qoq "$live" 2>/dev/null) \
            || { echo "error: $live has no owning package; nothing to reset to" >&2; exit 1; }
        ver=$(pacman -Q "$pkg" | awk '{print $2}')
        arch=$(pacman -Qi "$pkg" | awk -F': *' '/^Architecture/{print $2; exit}')
        cache=""
        for ext in zst xz; do
            c="/var/cache/pacman/pkg/${pkg}-${ver}-${arch}.pkg.tar.${ext}"
            [ -f "$c" ] && { cache="$c"; break; }
        done
        if [ -z "$cache" ]; then
            echo "  fetching $pkg from mirror..." >&2
            sudo pacman -Sw --noconfirm "$pkg" >/dev/null || true
            for ext in zst xz; do
                c="/var/cache/pacman/pkg/${pkg}-${ver}-${arch}.pkg.tar.${ext}"
                [ -f "$c" ] && { cache="$c"; break; }
            done
        fi
        [ -n "$cache" ] || { echo "error: no cache for ${pkg}-${ver}; mirror may have moved past installed version" >&2; exit 1; }
        bsdtar -tf "$cache" "${live#/}" >/dev/null 2>&1 \
            || { echo "error: $live not present in $pkg archive" >&2; exit 1; }
        bsdtar -xOf "$cache" "${live#/}" > "$repo"
        echo "reset (from $pkg): $repo"
    done
    just apply

# Stop tracking one or more /etc files: reset to pristine, deploy, then drop from repo
etc-untrack +paths:
    just etc-reset {{ paths }}
    just etc-forget {{ paths }}

# Restore live /etc/<path> to pristine pacman contents (bypasses the repo)
etc-restore +paths:
    #!/usr/bin/env bash
    set -eo pipefail
    for raw in {{ paths }}; do
        case "$raw" in
            *..*|*/./*|./*|../*) echo "error: unsafe path: $raw" >&2; exit 1 ;;
        esac
        p=${raw#/}; p=${p#etc/}
        live=/etc/$p
        [ -e "$live" ] || { echo "error: $live does not exist" >&2; exit 1; }
        pkg=$(pacman -Qoq "$live" 2>/dev/null) \
            || { echo "error: $live has no owning package; nothing to restore to" >&2; exit 1; }
        ver=$(pacman -Q "$pkg" | awk '{print $2}')
        arch=$(pacman -Qi "$pkg" | awk -F': *' '/^Architecture/{print $2; exit}')
        cache=""
        for ext in zst xz; do
            c="/var/cache/pacman/pkg/${pkg}-${ver}-${arch}.pkg.tar.${ext}"
            [ -f "$c" ] && { cache="$c"; break; }
        done
        if [ -z "$cache" ]; then
            echo "  fetching $pkg from mirror..." >&2
            sudo pacman -Sw --noconfirm "$pkg" >/dev/null || true
            for ext in zst xz; do
                c="/var/cache/pacman/pkg/${pkg}-${ver}-${arch}.pkg.tar.${ext}"
                [ -f "$c" ] && { cache="$c"; break; }
            done
        fi
        [ -n "$cache" ] || { echo "error: no cache for ${pkg}-${ver}; mirror may have moved past installed version" >&2; exit 1; }
        bsdtar -tf "$cache" "${live#/}" >/dev/null 2>&1 \
            || { echo "error: $live not present in $pkg archive" >&2; exit 1; }
        # Extract with -p to preserve owner/mode/mtime so pacman -Qkk sees the
        # file as unmodified (same metadata as install time, not just same bytes).
        sudo bsdtar -xpf "$cache" -C / "${live#/}"
        echo "restored (from $pkg): $live"
    done

# ═══════════════════════════════════════════════════════════════════
# Package domain
# ═══════════════════════════════════════════════════════════════════

# Show package drift: missing packages in adopted groups + undeclared installed packages
pkg-status:
    #!/bin/sh
    flatpaks=$(flatpak list --user --app --columns=application 2>/dev/null || true)
    echo "=== Package drift ==="
    just _active-packages | while read -r pkg; do
        [ -z "$pkg" ] && continue
        pacman -Qi "$pkg" >/dev/null 2>&1 || echo "  missing:    $pkg"
    done
    if [ -f meta/flatpak.txt ]; then
        awk '!/^[[:space:]]*(#|$)/ {print $1}' meta/flatpak.txt | while read -r id; do
            [ -z "$id" ] && continue
            printf '%s\n' "$flatpaks" | grep -qxF "$id" || echo "  missing:    flatpak: $id"
        done
    fi
    just undeclared | sed 's/^/  undeclared: /'

# Print undeclared packages one per line, unindented (pipe to 'paru -Rs -' to remove pacman entries)
undeclared:
    #!/bin/sh
    active=$(just _active-packages)
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

# Show per-group install coverage; pass a group name for a per-package breakdown
pkg-list group="":
    #!/bin/sh
    is_installed() {
        # $1: group name, $2: package/app id
        if [ "$1" = "flatpak" ]; then
            printf '%s\n' "$_flatpaks" | grep -qxF "$2"
        else
            pacman -Qi "$2" >/dev/null 2>&1
        fi
    }
    _flatpaks=$(flatpak list --user --app --columns=application 2>/dev/null || true)
    if [ -n '{{ group }}' ]; then
        file="meta/{{ group }}.txt"
        if [ ! -f "$file" ]; then
            echo "error: $file does not exist" >&2
            exit 1
        fi
        if [ '{{ group }}' = "flatpak" ]; then
            parser='!/^[[:space:]]*(#|$)/ {print $1}'
            awk "$parser" "$file" | while read -r pkg; do
                if is_installed '{{ group }}' "$pkg"; then
                    printf '  \033[32m✓\033[0m %s\n' "$pkg"
                else
                    printf '  \033[31m✗\033[0m %s\n' "$pkg"
                fi
            done
        else
            sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "$file" | while read -r pkg; do
                if is_installed '{{ group }}' "$pkg"; then
                    printf '  \033[32m✓\033[0m %s\n' "$pkg"
                else
                    printf '  \033[31m✗\033[0m %s\n' "$pkg"
                fi
            done
        fi
        exit 0
    fi
    for file in meta/*.txt; do
        group=$(basename "$file" .txt)
        if [ "$group" = "flatpak" ]; then
            pkgs=$(awk '!/^[[:space:]]*(#|$)/ {print $1}' "$file")
        else
            pkgs=$(sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "$file")
        fi
        total=$(echo "$pkgs" | wc -l)
        installed=0
        for pkg in $pkgs; do
            is_installed "$group" "$pkg" && installed=$((installed + 1))
        done
        if [ "$installed" -eq "$total" ]; then
            printf '  \033[32m✓\033[0m %-10s %d/%d\n' "$group" "$installed" "$total"
        elif [ $((installed * 2)) -ge "$total" ]; then
            printf '  \033[33m~\033[0m %-10s %d/%d\n' "$group" "$installed" "$total"
        else
            printf '  \033[31m✗\033[0m %-10s %d/%d\n' "$group" "$installed" "$total"
        fi
    done

# Install one or more package groups, or all groups if none given (e.g. just pkg-apply base intel)
pkg-apply *groups:
    #!/bin/sh
    set -eu
    if [ -n "{{ groups }}" ]; then
        for group in {{ groups }}; do
            file="meta/${group}.txt"
            if [ "$group" = "flatpak" ]; then
                just _flatpak-install
                continue
            fi
            pkgs=$(sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "$file")
            [ -n "$pkgs" ] || continue
            printf '%s\n' "$pkgs" | paru -S --needed --noconfirm --ask=4 -
        done
    else
        find meta -maxdepth 1 -name '*.txt' ! -name 'flatpak.txt' -print0 \
            | xargs -0 cat \
            | sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' \
            | sort -u | paru -S --needed --noconfirm --ask=4 -
        [ -f meta/flatpak.txt ] && just _flatpak-install
    fi

# Top up missing packages in groups that are already ≥50% installed (never installs new groups)
pkg-fix:
    #!/bin/sh
    flatpaks=$(flatpak list --user --app --columns=application 2>/dev/null || true)
    for file in meta/*.txt; do
        group=$(basename "$file" .txt)
        if [ "$group" = "flatpak" ]; then
            pkgs=$(awk '!/^[[:space:]]*(#|$)/ {print $1}' "$file")
        else
            pkgs=$(sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "$file")
        fi
        total=$(echo "$pkgs" | wc -l)
        installed=0
        for pkg in $pkgs; do
            if [ "$group" = "flatpak" ]; then
                printf '%s\n' "$flatpaks" | grep -qxF "$pkg" && installed=$((installed + 1))
            else
                pacman -Qi "$pkg" >/dev/null 2>&1 && installed=$((installed + 1))
            fi
        done
        if [ $((installed * 2)) -ge "$total" ] && [ "$installed" -lt "$total" ]; then
            echo ">>> topping up $group ($installed/$total installed)"
            if [ "$group" = "flatpak" ]; then
                just _flatpak-install
            else
                echo "$pkgs" | paru -S --needed --noconfirm --ask=4 -
            fi
        fi
    done

# Append one or more packages to a group list and install them (e.g. just pkg-add base ripgrep fd)
pkg-add group +pkgs:
    #!/bin/sh
    set -eu
    file="meta/{{ group }}.txt"
    if [ ! -f "$file" ]; then
        echo "error: $file does not exist" >&2
        exit 1
    fi
    for pkg in {{ pkgs }}; do
        if grep -qxF "$pkg" "$file"; then
            echo "$pkg already in {{ group }}.txt"
        else
            echo "$pkg" >> "$file"
            echo "added $pkg to {{ group }}.txt"
        fi
    done
    if [ '{{ group }}' = "flatpak" ]; then
        flatpak remote-add --if-not-exists --user flathub \
            https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null
        flatpak install --user -y --noninteractive flathub {{ pkgs }}
    else
        paru -S --needed {{ pkgs }}
    fi

# Remove one or more packages from a group list (does NOT uninstall; the package may belong to other groups)
pkg-forget group +pkgs:
    #!/bin/sh
    set -eu
    file="meta/{{ group }}.txt"
    if [ ! -f "$file" ]; then
        echo "error: $file does not exist" >&2
        exit 1
    fi
    for pkg in {{ pkgs }}; do
        if grep -qxF "$pkg" "$file"; then
            sed -i "/^$(printf '%s' "$pkg" | sed 's/[]\/$*.^[]/\\&/g')\$/d" "$file"
            echo "removed $pkg from {{ group }}.txt"
        else
            echo "$pkg not in {{ group }}.txt"
        fi
    done

# ═══════════════════════════════════════════════════════════════════
# Hidden helpers (run indirectly via the recipes above)
# ═══════════════════════════════════════════════════════════════════

_chezmoi-init:
    chezmoi init -S .

_install-hooks:
    git config core.hooksPath .githooks

# Install all flatpaks declared in meta/flatpak.txt. Flathub IDs are batched
# into a single install call; URL bundles are downloaded and installed only
# when the app id is not already present (use `flatpak-update` to pick up

# new versions of bundle entries).
_flatpak-install:
    #!/bin/sh
    set -eu
    [ -f meta/flatpak.txt ] || exit 0
    flatpak remote-add --if-not-exists --user flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null
    flathub_ids=$(awk '!/^[[:space:]]*(#|$)/ && NF==1 {print $1}' meta/flatpak.txt)
    if [ -n "$flathub_ids" ]; then
        # shellcheck disable=SC2086
        flatpak install --user -y --noninteractive flathub $flathub_ids
    fi
    installed=$(flatpak list --user --app --columns=application 2>/dev/null || true)
    awk '!/^[[:space:]]*(#|$)/ && NF>=2 {print $1, $2}' meta/flatpak.txt \
        | while read -r id url; do
            if printf '%s\n' "$installed" | grep -qxF "$id"; then
                continue
            fi
            echo ">>> downloading $id from $url"
            tmp=$(mktemp --suffix=.flatpak)
            curl -fsSL -o "$tmp" "$url"
            flatpak install --user -y --noninteractive "$tmp"
            rm -f "$tmp"
        done

# Print packages from pacman groups that are ≥50% installed (adopted), one per line
_active-packages:
    #!/bin/sh
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
