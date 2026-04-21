# Show available recipes (default)
default:
    @just --list


# ═══════════════════════════════════════════════════════════════════
# Setup
# ═══════════════════════════════════════════════════════════════════

# First-time machine setup: regenerate chezmoi config, install git hooks, install base packages
init: _chezmoi-init _install-hooks (install "base")


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
            echo "$pkgs" | paru -S --needed -
        fi
    done


# ═══════════════════════════════════════════════════════════════════
# Inspection
# ═══════════════════════════════════════════════════════════════════

# Show package and dotfile drift (only for groups ≥50% installed)
status:
    #!/bin/sh
    active_file=$(mktemp)
    trap 'rm -f "$active_file"' EXIT
    for file in meta/*.txt; do
        pkgs=$(grep -v '^\s*#' "$file" | grep -v '^\s*$')
        total=$(echo "$pkgs" | wc -l)
        installed=0
        for pkg in $pkgs; do
            pacman -Qi "$pkg" >/dev/null 2>&1 && installed=$((installed + 1))
        done
        if [ $((installed * 2)) -ge "$total" ]; then
            echo "$pkgs" >> "$active_file"
        fi
    done
    active=$(sort -u "$active_file")
    declared=$(cat meta/*.txt | grep -v '^\s*#' | grep -v '^\s*$' | sort -u)
    echo "=== Package drift ==="
    echo "$active" | while read -r pkg; do
        [ -z "$pkg" ] && continue
        pacman -Qi "$pkg" >/dev/null 2>&1 || echo "  missing:    $pkg"
    done
    pacman -Qqe | while read -r pkg; do
        echo "$declared" | grep -qxF "$pkg" || echo "  undeclared: $pkg"
    done
    echo ""
    echo "=== Dotfile drift ==="
    chezmoi status -S . || true

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
        elif [ "$installed" -eq 0 ]; then
            printf '  \033[31m✗\033[0m %-10s %d/%d\n' "$group" "$installed" "$total"
        else
            printf '  \033[33m~\033[0m %-10s %d/%d\n' "$group" "$installed" "$total"
        fi
    done


# ═══════════════════════════════════════════════════════════════════
# Package management
# ═══════════════════════════════════════════════════════════════════

# Install one or more package groups (e.g. just install base dev wayland)
install *groups:
    #!/bin/sh
    for group in {{ groups }}; do
        grep -v '^\s*#' "meta/${group}.txt" | grep -v '^\s*$' | paru -S --needed -
    done

# Install every package group
install-all:
    #!/bin/sh
    cat meta/*.txt | grep -v '^\s*#' | grep -v '^\s*$' | sort -u | paru -S --needed -

# Append a package to a group list and install it (e.g. just add dev ripgrep)
add group pkg:
    #!/bin/sh
    set -eu
    file="meta/{{ group }}.txt"
    if [ ! -f "$file" ]; then
        echo "error: $file does not exist" >&2
        exit 1
    fi
    if grep -qxF '{{ pkg }}' "$file"; then
        echo "{{ pkg }} already in {{ group }}.txt"
    else
        echo '{{ pkg }}' >> "$file"
        echo "added {{ pkg }} to {{ group }}.txt"
    fi
    paru -S --needed '{{ pkg }}'


# ═══════════════════════════════════════════════════════════════════
# Hidden helpers (run indirectly via the recipes above)
# ═══════════════════════════════════════════════════════════════════

[private]
_chezmoi-init:
    chezmoi init -S .

[private]
_install-hooks:
    git config core.hooksPath .githooks
