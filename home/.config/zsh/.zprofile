# Login shell configuration — sourced once per session by zsh.
# Sets environment variables, XDG paths, tool config, and host-specific overrides.

# Guard against double-sourcing (e.g. nested login shells)
[[ -n $__ZPROFILE_SOURCED ]] && return
__ZPROFILE_SOURCED=1

# ── PATH ──────────────────────────────────────────────────────────────────────
typeset -U path  # deduplicate PATH entries
path=("$HOME/.local/bin" "$HOME/.local/share/nvim/mason/bin" $path)

# ── XDG Base Directories ─────────────────────────────────────────────────────
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# ── Locale ────────────────────────────────────────────────────────────────────
export LANG=en_US.UTF-8

# ── Terminal ──────────────────────────────────────────────────────────────────
case $TERM in
    *256color|*truecolor) export COLORTERM=24bit ;;
esac

export TERMINAL='ghostty'
export BROWSER='linkhandler'
export OPENER='xdg-open'

# ── Editors ───────────────────────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
export DIFFPROG='nvim -d'
export MANPAGER='nvim +Man!'
export MANWIDTH=999

# ── less ──────────────────────────────────────────────────────────────────────
export LESS="-F --RAW-CONTROL-CHARS"
[[ -r /usr/bin/source-highlight-esc.sh ]] && export LESSOPEN="| /usr/bin/source-highlight-esc.sh %s"

# ── GPG / SSH ─────────────────────────────────────────────────────────────────
export GPG_TTY=$TTY
unset SSH_AGENT_PID
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"

# ── FZF ───────────────────────────────────────────────────────────────────────
export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --exclude .git --color=always"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DIRS_COMMAND="fd --type d --follow --hidden --exclude .git --color=always"
export FZF_DEFAULT_OPTS="--ansi --layout=reverse --inline-info --cycle --color=dark --color=fg:-1,bg:-1,hl:#5fff87,fg+:-1,bg+:-1,hl+:#ffaf5f --color=info:#af87ff,prompt:#5fff87,pointer:#ff87d7,marker:#ff87d7,spinner:#ff87d7"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}' --select-1 --exit-0"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview' --sort --exact"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

# ── Git prompt ────────────────────────────────────────────────────────────────
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
unset GIT_PS1_SHOWUNTRACKEDFILES
export GIT_PS1_SHOWUPSTREAM="verbose"
export GIT_PS1_SHOWCONFLICTSTATE="yes"
export GIT_PS1_DESCRIBE_STYLE="branch"
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_HIDE_IF_PWD_IGNORED=1

# ── GCC ───────────────────────────────────────────────────────────────────────
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# ── Java ──────────────────────────────────────────────────────────────────────
# System AA fonts, GTK L&F, XDG prefs dir, GTK2 for compatibility
export _JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel -Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java -Djdk.gtk.version=2"
# Fix for non-reparenting WMs (sway, dwm, etc.)
export _JAVA_AWT_WM_NONREPARENTING=1

# ── Miscellaneous ─────────────────────────────────────────────────────────────
export QT_QPA_PLATFORMTHEME=qt6ct
export NO_AT_BRIDGE=1          # suppress GTK accessibility bus warnings
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
export INPUTRC="$XDG_CONFIG_HOME/sh/inputrc"

# ── Wayland ───────────────────────────────────────────────────────────────────
export XDG_CURRENT_DESKTOP=sway
export MOZ_ENABLE_WAYLAND=1

# ── XDG cleanup: keep $HOME tidy ─────────────────────────────────────────────
# https://wiki.archlinux.org/title/XDG_Base_Directory#Partial
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
export GOPATH="$XDG_DATA_HOME/go"
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store"
export RUFF_CACHE_DIR="$XDG_CACHE_HOME/ruff"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"
export WINEPREFIX="$XDG_DATA_HOME/wineprefixes/default"

# ── Host-specific ─────────────────────────────────────────────────────────────
case $(uname -n) in
    halley2)
        export LIBVA_DRIVER_NAME="iHD"
        export MESA_LOADER_DRIVER_OVERRIDE="iris"
        export VAAPI_MPEG4_ENABLED=true
        ;;
    hercules)
        export OCL_ICD_VENDORS=nvidia
        [[ -r "$XDG_CONFIG_HOME/sh/work-envrc" ]] && source "$XDG_CONFIG_HOME/sh/work-envrc"
        ;;
esac

# ── Secrets (from pass) ──────────────────────────────────────────────────────
(( $+commands[pass] )) && export FIRECRAWL_API_KEY="$(pass show copilot/firecrawl-api-key)"

# ── Auto-start sway on VT1 ────────────────────────────────────────────────────
if [[ -z $WAYLAND_DISPLAY && $XDG_VTNR == 1 ]]; then
    export XDG_SESSION_TYPE=wayland
    exec sway
fi
