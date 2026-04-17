# Interactive zsh configuration.

# ── Terminal ──────────────────────────────────────────────────────────────────
stty -ixon   # disable XON/XOFF flow control (frees Ctrl-S/Ctrl-Q)
ttyctl -f    # freeze terminal state; programs can't leave it broken

# ── Options ───────────────────────────────────────────────────────────────────
# Note: appendhistory, nomatch, notify are zsh defaults — not set here.
setopt autocd              # cd by typing directory name
setopt extendedglob        # extended glob patterns (#, ~, ^)
setopt interactivecomments # allow # comments in interactive shell
setopt rmstarsilent        # don't confirm rm *
setopt prompt_subst        # expand variables/functions in prompt
setopt auto_pushd          # cd pushes old dir onto stack (cd -<TAB> to browse)
setopt pushd_ignore_dups   # don't push duplicate dirs onto stack
unsetopt beep              # no terminal bell

# ── History ───────────────────────────────────────────────────────────────────
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
setopt extended_history       # save timestamp and duration per entry
setopt share_history          # share history across concurrent sessions
setopt hist_ignore_all_dups   # remove older duplicate when adding new entry
setopt hist_find_no_dups      # skip duplicates when searching history
setopt hist_reduce_blanks     # trim superfluous whitespace from entries
setopt hist_ignore_space      # commands starting with space are not saved

# ── Emacs keybindings ─────────────────────────────────────────────────────────
bindkey -e

# ── Prompt ────────────────────────────────────────────────────────────────────
autoload -Uz colors && colors
source /usr/share/git/completion/git-prompt.sh
PROMPT='%B%{$fg[green]%}%n%{$reset_color%}@%{$fg[cyan]%}%m%{$reset_color%}:%b%{$fg[yellow]%}%~%{$reset_color%}$(__git_ps1 " (%s)")%(?..[%{$fg[red]%}%?%{$reset_color%}]) %(!.#.>) '

# ── Completion ────────────────────────────────────────────────────────────────
fpath=($XDG_DATA_HOME/zsh/completion $fpath)
autoload -Uz compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

zstyle ':completion:*' menu select                       # arrow-key driven menu for ambiguous completions
zstyle ':completion:*' completer _expand_alias _complete _ignored _match _approximate
#                                │              │         │        │      └ fuzzy match (typo tolerance)
#                                │              │         │        └ try pattern matching
#                                │              │         └ include normally hidden completions
#                                │              └ standard completion
#                                └ expand aliases before completing
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}  # colorize file completions like ls
zstyle ':completion:*' use-cache on                            # cache completions (speeds up pip, dpkg, etc.)
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh"
zstyle ':completion:*:match:*' original only                   # only show original when pattern-matching
zstyle ':completion:*:functions' ignored-patterns '_*'         # hide internal completion functions
zstyle ':completion:*:*:kill:*' menu yes select                # interactive menu for kill completion
zstyle ':completion:*:kill:*' force-list always                # always show process list for kill
zstyle ':completion:*:cd:*' ignore-parents parent pwd          # cd never completes . or ..
zstyle ':completion::complete:*' gain-privileges 1             # use doas/sudo for privileged completions
zstyle -e ':completion:*:approximate:*' \
	max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'    # allow 1 typo per 3 chars typed

_comp_options+=(globdots)  # include hidden files in completion

# ── Terminal key setup ─────────────────────────────────────────────────────────
# Application mode ensures terminfo values are valid during line editing.
# Without this, some terminals send wrong sequences for special keys.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start { echoti smkx }
	function zle_application_mode_stop  { echoti rmkx }
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

# Up/Down stored for history-substring-search bindings (set after plugin source)
typeset -g -A key
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"

# ── Custom keybindings ────────────────────────────────────────────────────────
bindkey \^U backward-kill-line

# Word navigation (Ctrl-Right also accepts autosuggestion word-by-word — fish-like)
bindkey '^[[1;5C' forward-word        # Ctrl-Right
bindkey '^[[1;5D' backward-word       # Ctrl-Left
bindkey '^[[1;3C' forward-word        # Alt-Right
bindkey '^[[1;3D' backward-word       # Alt-Left
bindkey '^H'      backward-kill-word  # Ctrl-Backspace
bindkey '^[[3;5~' kill-word           # Ctrl-Delete

# Ctrl-Z: toggle foreground/background (no need to type 'fg')
toggle-fg-bg() {
	if (( ${#jobstates} )); then
		zle .push-input
		BUFFER="fg"
		zle .accept-line
	else
		zle .push-input
		zle .clear-screen
	fi
}
zle -N toggle-fg-bg
bindkey '^Z' toggle-fg-bg

# Ctrl-D exits even on non-empty line
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh

# Ctrl-X Ctrl-E: edit command in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# Ctrl-Y: copy current command line to clipboard (OSC 52 — terminal-native)
copy-line-to-clipboard() { printf '\033]52;c;%s\a' "$(echo -n "$BUFFER" | base64)" }
zle -N copy-line-to-clipboard
bindkey '^Y' copy-line-to-clipboard

# ── Word style ────────────────────────────────────────────────────────────────
# Ctrl-W/Alt-B/Alt-F use shell quoting rules for word boundaries
autoload -Uz select-word-style
select-word-style shell

# ── Smart dot expansion ───────────────────────────────────────────────────────
# Typing .. automatically expands: ... → ../.. , .... → ../../.. , etc.
rationalise-dot() {
	if [[ $LBUFFER = *.. ]]; then
		LBUFFER+=/..
	else
		LBUFFER+=.
	fi
}
zle -N rationalise-dot
bindkey . rationalise-dot

# ── Window title ──────────────────────────────────────────────────────────────
autoload -Uz add-zsh-hook

xterm_title_precmd()  { print -Pn -- '\e]2;%~\a' }
xterm_title_preexec() { print -Pn -- '\e]2;%~ %# ' && print -n -- "${(q)1}\a" }

if [[ "$TERM" == (alacritty|st*|screen*|xterm*|rxvt*|tmux*|putty*|konsole*|gnome*) ]]; then
	add-zsh-hook -Uz precmd xterm_title_precmd
	add-zsh-hook -Uz preexec xterm_title_preexec
fi

# ── Zellij tab naming (dir:cmd like tmux) ────────────────────────────────────
if [[ -n "$ZELLIJ" ]]; then
	_zellij_dir() { [[ "$PWD" == "$HOME" ]] && echo '~' || echo "${PWD##*/}"; }
	_zellij_tab_precmd()  { zellij action rename-tab "$(_zellij_dir)" 2>/dev/null; }
	_zellij_tab_preexec() { zellij action rename-tab "$(_zellij_dir):${1%% *}" 2>/dev/null; }
	add-zsh-hook precmd _zellij_tab_precmd
	add-zsh-hook preexec _zellij_tab_preexec
fi

# ── Recent directories ────────────────────────────────────────────────────────
autoload -Uz chpwd_recent_dirs cdr
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ':chpwd:*' recent-dirs-file "$XDG_STATE_HOME/zsh/chpwd-recent-dirs"
zstyle ':completion:*:*:cdr:*:*' menu selection

# ── Help system ───────────────────────────────────────────────────────────────
autoload -Uz run-help run-help-git run-help-ip
(( $+aliases[run-help] )) && unalias run-help
alias help=run-help

# ── Bracketed paste ───────────────────────────────────────────────────────────
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

# ── Aliases ───────────────────────────────────────────────────────────────────
# Files
alias l='lsd -l'
alias la='lsd -lA'
alias lt='lsd --tree'
alias mkdir='mkdir -p'
alias du='du -h'
alias df='df -h'
alias free='free -h'

# Grep / diff with color
alias grep='grep --color=auto'
alias fgrep='grep -F --color=auto'
alias egrep='grep -E --color=auto'
alias diff='diff --color=auto'
alias dmesg='dmesg --color=auto'
alias dm='dmesg --color=always | less -r'

# Networking
alias ip="ip -color=auto"
alias lsip="ip -human -color=auto --brief address show"
alias ipa="ip -stats -details -human -color=auto address show"
alias ipecho='curl ipecho.net/plain'
alias ss='doas ss -tupnl'

# Privilege escalation
alias sudo='doas'
alias sudoedit='doasedit'
alias gimme='doas chown $USER:$(id -gn $USER)'
alias pacdiff='doas pacdiff'

# Pacman
alias pacopt='comm -13 <(pacman -Qqdt | sort) <(pacman -Qqdtt | sort)'

# Git
alias g='git'

# Systemd
alias sys='systemctl'
alias ssys='doas systemctl'
alias sysu='systemctl --user'

# Navigation
alias c='clear'

# Tools
alias stow='stow -R --no-folding --adopt'
alias curl='curlie'
alias xclip="xclip -selection clipboard -f"
alias cpr='rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1'
alias mvr='rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1 --remove-source-files'
alias sub='subliminal download -l en'

# Neovim
alias n='nvim'
alias ndiff='nvim -d'
alias nd='nvim -d'
alias nview='nvim -R'
alias nv='nvim -R'
alias ng='nvim +Neogit'

# Zellij: smart attach — 0 sessions: create, 1: attach, many: welcome picker
za() {
	local sessions=$(zellij list-sessions -ns 2>/dev/null | wc -l)
	if (( sessions == 0 )); then
		zellij
	elif (( sessions == 1 )); then
		zellij attach
	else
		zellij -l welcome
	fi
}

# Just
alias j='just'

# X11 keyboard inspection
whichkey() {
	xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'
}

# LLVM / Clang tooling
alias ncmake='cmake -G Ninja -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_C_FLAGS="$DEV_CFLAGS" -DCMAKE_CXX_FLAGS="$DEV_CFLAGS" -DCMAKE_INSTALL_PREFIX=build/install -DCMAKE_BUILD_TYPE=Debug -DBUILD_SHARED_LIBS=ON -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B build'
alias ircc='clang -S -emit-llvm -fno-discard-value-names -O0 -Xclang -disable-O0-optnone -o -'
alias irfc='flang -S -emit-llvm -O0 -o -'
alias astcc='clang -Xclang -ast-dump -fsyntax-only'
alias astfc='flang -fc1 -fdebug-dump-parse-tree'
alias symfc='flang -fc1 -fdebug-dump-symbols'
alias gdbr='gdb -ex start --args'

# GitHub Copilot CLI
alias copilot='gh copilot --autopilot --enable-all-github-mcp-tools --yolo --resume'

# ── Alias completions ─────────────────────────────────────────────────────────
compdef g=git
compdef j=just
compdef n=nvim ndiff=nvim nd=nvim nview=nvim nv=nvim
compdef sys=systemctl ssys=systemctl sysu=systemctl
compdef l=lsd la=lsd lt=lsd

# ── GPG agent ─────────────────────────────────────────────────────────────────
# Refresh gpg-agent's TTY so pinentry prompts appear in the right terminal
gpg-connect-agent updatestartuptty /bye &>/dev/null

# ── Zoxide (smart directory jumping) ──────────────────────────────────────────
# z foo → jump to frecency-ranked dir matching "foo"
# zi    → interactive picker with fzf
eval "$(zoxide init zsh)"

# ── FZF ───────────────────────────────────────────────────────────────────────
source <(fzf --zsh)

# Ctrl-X Ctrl-R: search history with fzf and immediately execute
fzf-history-widget-accept() {
	fzf-history-widget
	zle accept-line
}
zle -N fzf-history-widget-accept
bindkey '^X^R' fzf-history-widget-accept

_fzf_compgen_path() { fd --hidden --follow --exclude ".git" . "$1" }
_fzf_compgen_dir()  { fd --type d --hidden --follow --exclude ".git" . "$1" }

# ── Plugins (must be sourced last) ────────────────────────────────────────────
# Highlight config must be set BEFORE sourcing the plugin
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]='fg=yellow'
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^[[Z' autosuggest-accept  # Shift-Tab to accept suggestion

source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
[[ -n "${key[Up]}"   ]] && bindkey -- "${key[Up]}"   history-substring-search-up
[[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" history-substring-search-down
