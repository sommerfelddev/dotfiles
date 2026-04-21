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
