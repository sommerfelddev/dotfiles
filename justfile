# Install git hooks
install-hooks:
    git config core.hooksPath .githooks

# Deploy dotfiles
apply:
    chezmoi apply

# Install packages from one or more groups (e.g. just install base dev wayland)
install *groups:
    #!/bin/sh
    for group in {{ groups }}; do
        grep -v '^\s*#' "meta/${group}.txt" | grep -v '^\s*$' | paru -S --needed -
    done

# Install all package groups
install-all:
    #!/bin/sh
    cat meta/*.txt | grep -v '^\s*#' | grep -v '^\s*$' | sort -u | paru -S --needed -

# Fill in missing packages for groups that are already partially/fully installed
fix:
    #!/bin/sh
    for file in meta/*.txt; do
        group=$(basename "$file" .txt)
        pkgs=$(grep -v '^\s*#' "$file" | grep -v '^\s*$')
        for pkg in $pkgs; do
            if pacman -Qi "$pkg" >/dev/null 2>&1; then
                echo ">>> topping up $group"
                echo "$pkgs" | paru -S --needed -
                break
            fi
        done
    done

# Add a package to a group and install it (e.g. just add dev ripgrep)
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

# Show package and dotfile drift
status:
    #!/bin/sh
    echo "=== Package drift ==="
    declared=$(cat meta/*.txt | grep -v '^\s*#' | grep -v '^\s*$' | sort -u)
    echo "$declared" | while read -r pkg; do
        pacman -Qi "$pkg" >/dev/null 2>&1 || echo "  missing:    $pkg"
    done
    pacman -Qqe | while read -r pkg; do
        echo "$declared" | grep -qxF "$pkg" || echo "  undeclared: $pkg"
    done
    echo ""
    echo "=== Dotfile drift ==="
    chezmoi status || true

# Show install coverage for each group (or full breakdown for one group)
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
