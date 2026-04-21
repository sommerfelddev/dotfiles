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


# ═══════════════════════════════════════════════════════════════════
# Inspection
# ═══════════════════════════════════════════════════════════════════

# Show package and dotfile drift (runs pkg-drift + dotfile-drift)
status: pkg-drift dotfile-drift

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

# Show dotfile diffs; pass a path to limit to a single file (e.g. just diff .config/nvim/init.lua)
diff file="":
    chezmoi diff -S . {{ file }}

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
etc-drift:
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
    pacman -Qii 2>/dev/null | grep -oP 'MODIFIED\t\K/\S+' | sort -u \
        | while IFS= read -r p; do keep "$p" && echo "  modified: $p"; done

    echo "--- user-created (no owning package) ---"
    find /etc -xdev -type f -print0 2>/dev/null \
        | xargs -0 pacman -Qo 2>&1 >/dev/null \
        | sed -n 's/^error: No package owns //p' | sort -u \
        | while IFS= read -r p; do keep "$p" && echo "  unowned:  $p"; done


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
