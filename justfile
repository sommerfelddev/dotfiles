# Show available recipes (default)
default:
    @just --list

# ═══════════════════════════════════════════════════════════════════
# Setup
# ═══════════════════════════════════════════════════════════════════

# First-time machine setup: regenerate chezmoi config, install git hooks, deploy dotfiles, install base packages
init: _chezmoi-init _install-hooks apply (install "base") services-enable

# ═══════════════════════════════════════════════════════════════════
# Day-to-day
# ═══════════════════════════════════════════════════════════════════

# Reconcile everything: deploy dotfiles AND top up partially-installed package groups
sync: apply fix

# Deploy dotfiles (chezmoi apply)
apply:
    chezmoi apply -S .

# Re-add changes from live files back into the repo (chezmoi re-add + etc-readd)
readd:
    chezmoi re-add
    just etc-readd

# Top up missing packages in groups that are already ≥50% installed (never installs new groups)
fix:
    #!/bin/sh
    for file in meta/*.txt; do
        group=$(basename "$file" .txt)
        pkgs=$(grep -v '^\s*#' "$file" | grep -v '^\s*$')
        total=$(echo "$pkgs" | wc -l)
        installed=0
        for pkg in $pkgs; do
            pacman -Qi "$pkg" >/dev/null 2>&1 && installed=$((installed + 1))
        done
        if [ $((installed * 2)) -ge "$total" ] && [ "$installed" -lt "$total" ]; then
            echo ">>> topping up $group ($installed/$total installed)"
            echo "$pkgs" | paru -S --needed --noconfirm --ask=4 -
        fi
    done

# Format code; pass a path to format a single file, or omit to format everything
fmt *target:
    #!/usr/bin/env bash
    set -eo pipefail

    _need() {
      command -v "$1" >/dev/null 2>&1 || {
        printf 'error: %s not on PATH (install: %s)\n' "$1" "$2" >&2
        exit 1
      }
    }

    _fmt_lua()      { _need stylua stylua;        stylua "$@"; }
    _fmt_sh()       { _need shfmt shfmt;          shfmt -w -i 2 -ci -s "$@"; }
    _fmt_py()       { _need ruff ruff;            ruff format "$@"; }
    _fmt_toml()     { _need taplo taplo-cli;      taplo format "$@"; }
    _fmt_just()     { just --unstable --fmt; }
    _fmt_prettier() { _need prettier prettier;    prettier --write "$@"; }

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

    _is_zsh() {
      case "$(basename "$1")" in
        dot_zshrc|dot_zshenv|dot_zprofile|.zshrc|.zshenv|.zprofile) return 0 ;;
      esac
      return 1
    }

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
        if head -1 "$target" 2>/dev/null | grep -qE '^#!.*\b(ba)?sh\b'; then
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

    _need() {
      command -v "$1" >/dev/null 2>&1 || {
        printf 'error: %s not on PATH (install: %s)\n' "$1" "$2" >&2
        exit 1
      }
    }

    _chk_lua()      { _need stylua stylua;        stylua --check "$@"; }
    _chk_sh()       { _need shfmt shfmt;          shfmt -d -i 2 -ci -s "$@"; }
    _chk_py()       { _need ruff ruff;            ruff format --check "$@"; }
    _chk_toml()     { _need taplo taplo-cli;      taplo format --check "$@"; }
    _chk_just()     { just --unstable --fmt --check; }
    _chk_prettier() { _need prettier prettier;    prettier --check "$@"; }

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

    _is_zsh() {
      case "$(basename "$1")" in
        dot_zshrc|dot_zshenv|dot_zprofile|.zshrc|.zshenv|.zprofile) return 0 ;;
      esac
      return 1
    }

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
        if head -1 "$target" 2>/dev/null | grep -qE '^#!.*\b(ba)?sh\b'; then
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

    _need() {
      command -v "$1" >/dev/null 2>&1 || {
        printf 'error: %s not on PATH (install: %s)\n' "$1" "$2" >&2
        exit 1
      }
    }

    _lint_lua()      { _need selene selene;         selene "$@"; }
    _lint_sh()       { _need shellcheck shellcheck; shellcheck "$@"; }
    _lint_zsh()      { _need shellcheck shellcheck; shellcheck --shell=bash "$@"; }
    _lint_py()       { _need ruff ruff;             ruff check "$@"; }
    _lint_toml()     { _need taplo taplo-cli;       taplo lint "$@"; }

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
        dot_zshrc|dot_zshenv|dot_zprofile|.zshrc|.zshenv|.zprofile) return 0 ;;
      esac
      return 1
    }

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
        if head -1 "$target" 2>/dev/null | grep -qE '^#!.*\b(ba)?sh\b'; then
          _lint_sh "$target"
        else
          echo "error: no linter for: $target" >&2; exit 1
        fi
        ;;
    esac

# ═══════════════════════════════════════════════════════════════════
# Inspection
# ═══════════════════════════════════════════════════════════════════

# Show package, dotfile, /etc, and service drift
status: dotfile-drift pkg-drift etc services-drift

# Show package drift: missing packages in adopted groups + undeclared installed packages
pkg-drift:
    #!/bin/sh
    active=$(just _active-packages)
    echo "=== Package drift ==="
    echo "$active" | while read -r pkg; do
        [ -z "$pkg" ] && continue
        pacman -Qi "$pkg" >/dev/null 2>&1 || echo "  missing:    $pkg"
    done
    just undeclared | sed 's/^/  undeclared: /'

# Show dotfile drift (wraps 'chezmoi status')
dotfile-drift:
    #!/bin/sh
    echo "=== Dotfile drift ==="
    chezmoi status -S . || true

# Print undeclared packages one per line, unindented (pipe to 'paru -Rs -' to remove them)
undeclared:
    #!/bin/sh
    active=$(just _active-packages)
    pacman -Qqe | while read -r pkg; do
        echo "$active" | grep -qxF "$pkg" || echo "$pkg"
    done

# Show dotfile + /etc diffs; pass a path to limit to a single file (e.g. just diff .config/nvim/init.lua)
diff file="":
    #!/usr/bin/env bash
    set -eo pipefail
    f='{{ file }}'
    case "$f" in
        /etc/*|etc/*)
            just etc-diff "$f" ;;
        "")
            chezmoi diff -S .
            just etc-diff ;;
        *)
            chezmoi diff -S . "$f" ;;
    esac

# Resolve dotfile conflicts with a 3-way merge; pass a path for one file, or omit to merge all
merge file="":
    #!/bin/sh
    if [ -n '{{ file }}' ]; then
        chezmoi merge -S . '{{ file }}'
    else
        chezmoi merge-all -S .
    fi

# Show per-group install coverage; pass a group name for a per-package breakdown
groups group="":
    #!/bin/sh
    if [ -n '{{ group }}' ]; then
        file="meta/{{ group }}.txt"
        if [ ! -f "$file" ]; then
            echo "error: $file does not exist" >&2
            exit 1
        fi
        grep -v '^\s*#' "$file" | grep -v '^\s*$' | while read -r pkg; do
            if pacman -Qi "$pkg" >/dev/null 2>&1; then
                printf '  \033[32m✓\033[0m %s\n' "$pkg"
            else
                printf '  \033[31m✗\033[0m %s\n' "$pkg"
            fi
        done
        exit 0
    fi
    for file in meta/*.txt; do
        group=$(basename "$file" .txt)
        pkgs=$(grep -v '^\s*#' "$file" | grep -v '^\s*$')
        total=$(echo "$pkgs" | wc -l)
        installed=0
        for pkg in $pkgs; do
            pacman -Qi "$pkg" >/dev/null 2>&1 && installed=$((installed + 1))
        done
        if [ "$installed" -eq "$total" ]; then
            printf '  \033[32m✓\033[0m %-10s %d/%d\n' "$group" "$installed" "$total"
        elif [ $((installed * 2)) -ge "$total" ]; then
            printf '  \033[33m~\033[0m %-10s %d/%d\n' "$group" "$installed" "$total"
        else
            printf '  \033[31m✗\033[0m %-10s %d/%d\n' "$group" "$installed" "$total"
        fi
    done

# ═══════════════════════════════════════════════════════════════════
# Services
# ═══════════════════════════════════════════════════════════════════

# List curated systemd units (grouped by systemd-units/<group>.txt) with state
services:
    #!/bin/sh
    for file in systemd-units/*.txt; do
        [ -f "$file" ] || continue
        group=$(basename "$file" .txt)
        echo "=== $group ==="
        grep -v '^\s*#' "$file" | grep -v '^\s*$' | while read -r u; do
            en=$(systemctl is-enabled "$u" 2>/dev/null); en=${en:-unknown}
            ac=$(systemctl is-active  "$u" 2>/dev/null); ac=${ac:-unknown}
            case "$en" in
                enabled|static|alias)         c_en=32 ;;
                disabled|masked|not-found)    c_en=31 ;;
                *)                            c_en=33 ;;
            esac
            case "$ac" in
                active)                       c_ac=32 ;;
                inactive|failed)              c_ac=31 ;;
                *)                            c_ac=33 ;;
            esac
            printf '  %-34s \033[%sm%-10s\033[0m \033[%sm%s\033[0m\n' "$u" "$c_en" "$en" "$c_ac" "$ac"
        done
    done

# Enable all curated systemd units (idempotent, soft-fail per unit)
services-enable:
    #!/bin/sh
    for file in systemd-units/*.txt; do
        [ -f "$file" ] || continue
        grep -v '^\s*#' "$file" | grep -v '^\s*$' | while read -r u; do
            sudo systemctl enable --now "$u" \
                || echo "  warn: could not enable $u" >&2
        done
    done

# Show drift between curated services and actually-enabled services
services-drift:
    #!/bin/sh
    echo "=== Service drift ==="
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    cat systemd-units/*.txt 2>/dev/null \
        | grep -v '^\s*#' | grep -v '^\s*$' | sort -u > "$tmp/curated"
    if [ -f systemd-units/.ignore ]; then
        grep -v '^\s*#' systemd-units/.ignore | grep -v '^\s*$' | sort -u > "$tmp/ignore"
    else
        : > "$tmp/ignore"
    fi
    systemctl list-unit-files --state=enabled --no-legend 2>/dev/null \
        | awk '{print $1}' | grep -vE '@\.' | sort -u > "$tmp/enabled"
    comm -23 "$tmp/curated" "$tmp/enabled" | sed 's/^/  not-enabled: /'
    comm -13 "$tmp/curated" "$tmp/enabled" | comm -23 - "$tmp/ignore" | sed 's/^/  uncurated:   /'

# ═══════════════════════════════════════════════════════════════════
# System config (/etc)
# ═══════════════════════════════════════════════════════════════════

# Show /etc drift: package configs modified from defaults, plus user-created files
etc:
    #!/usr/bin/env bash
    set -eo pipefail
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

    find etc -type f ! -name .ignore 2>/dev/null \
        | sed 's|^etc/|/etc/|' | sort -u > "$tmp/managed"

    patterns=()
    if [ -f etc/.ignore ]; then
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            patterns+=("$line")
        done < etc/.ignore
    fi

    keep() {
        local path=$1
        grep -qxF "$path" "$tmp/managed" && return 1
        for pat in ${patterns[@]+"${patterns[@]}"}; do
            [[ "$path" == $pat ]] && return 1
        done
        return 0
    }

    echo "=== /etc drift ==="
    echo "--- modified package configs ---"
    { pacman -Qkk 2>/dev/null | grep -oP '^backup file:\s+[^:]+:\s+\K/etc/\S+' || true; } | sort -u \
        | while IFS= read -r p; do keep "$p" && echo "  modified: $p"; :; done

    echo "--- user-created (no owning package) ---"
    { find /etc -xdev -type f -print0 2>/dev/null \
        | xargs -0 pacman -Qo 2>&1 >/dev/null \
        | sed -n 's/^error: No package owns //p' || true; } | sort -u \
        | while IFS= read -r p; do keep "$p" && echo "  unowned:  $p"; :; done

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
        live=/etc/$p
        repo=etc/$p
        if [ ! -f "$repo" ]; then
            echo "skip: $live (not a regular file in etc/)" >&2; continue
        fi
        # Fast path for world-readable files; doas fallback only when needed (e.g. /etc/doas.conf 0600).
        if [ -r "$live" ]; then
            diff -u --label "$live" --label "$repo" "$live" "$repo" || true
        elif doas test -f "$live"; then
            diff -u --label "$live" --label "$repo" <(doas cat "$live") "$repo" || true
        else
            echo "skip: $live (missing or not a regular file on host)" >&2
        fi
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
        doas pacman -Sw --noconfirm "$pkg" >/dev/null || true
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
        elif doas test -f "$path"; then
            live_reader=(doas cat "$path")
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
        doas cp -a "$path" "$dest"
        doas chown "$USER:$USER" "$dest"
        echo "added: $path -> $dest"
    done
    echo
    echo "Run 'chezmoi apply' to sync (no-op content-wise, refreshes deploy hash)."

# Re-add changes from live /etc back into the repo (no args = all tracked files)
etc-readd *paths:
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
        live=/etc/$p
        repo=etc/$p
        [ -e "$live" ] || { echo "  missing live: $live (skipped)"; continue; }
        [ -f "$live" ] || { echo "  not a regular file: $live (skipped)"; continue; }
        if [ -r "$live" ]; then
            cat -- "$live" > "$repo.tmp"
        else
            doas cat -- "$live" > "$repo.tmp"
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
etc-rm +paths:
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
            doas pacman -Sw --noconfirm "$pkg" >/dev/null || true
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
    just etc-rm {{ paths }}

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
            doas pacman -Sw --noconfirm "$pkg" >/dev/null || true
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
        doas bsdtar -xpf "$cache" -C / "${live#/}"
        echo "restored (from $pkg): $live"
    done

# ═══════════════════════════════════════════════════════════════════
# Package management
# ═══════════════════════════════════════════════════════════════════

# Install one or more package groups (e.g. just install base dev wayland)
install *groups:
    #!/bin/sh
    for group in {{ groups }}; do
        grep -v '^\s*#' "meta/${group}.txt" | grep -v '^\s*$' | paru -S --needed --noconfirm --ask=4 -
    done

# Install every package group
install-all:
    #!/bin/sh
    cat meta/*.txt | grep -v '^\s*#' | grep -v '^\s*$' | sort -u | paru -S --needed --noconfirm --ask=4 -

# Append one or more packages to a group list and install them (e.g. just add dev ripgrep fd)
add group +pkgs:
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
    paru -S --needed {{ pkgs }}

# Remove one or more packages from a group list (does NOT uninstall; the package may belong to other groups)
remove group +pkgs:
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

# Print packages from groups that are ≥50% installed (adopted), one per line
_active-packages:
    #!/bin/sh
    for file in meta/*.txt; do
        pkgs=$(grep -v '^\s*#' "$file" | grep -v '^\s*$')
        total=$(echo "$pkgs" | wc -l)
        installed=0
        for pkg in $pkgs; do
            pacman -Qi "$pkg" >/dev/null 2>&1 && installed=$((installed + 1))
        done
        if [ $((installed * 2)) -ge "$total" ]; then
            echo "$pkgs"
        fi
    done | sort -u
