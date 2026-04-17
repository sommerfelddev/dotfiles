# Custom Keybinds Reference

All non-default keybinds across neovim, zellij, zsh, ghostty, and sway.

## Neovim

Leader: `Space` | Local leader: `,`

### General (config/keymaps.lua)

| Mode | Key | Action |
|------|-----|--------|
| n | `Esc` | Clear search highlight |
| n | `gV` | Select last inserted text |
| n | `↓` / `↑` | Scroll viewport (C-e / C-y) |
| v | `p` | Paste without clobbering register |
| n | `,s` | Find and replace (whole file) |
| v | `,s` | Find and replace (selection) |
| n | `Space x` | Write all buffers |
| n | `Space z` | Write all and quit |
| n | `Space q` | Quit all |
| t | `Esc Esc` | Exit terminal mode |
| n | `[w` / `]w` | Prev/next warning+ diagnostic |
| n | `[e` / `]e` | Prev/next error diagnostic |
| n | `yp` | Yank current file path to clipboard |
| | `:DoasWrite` | Write file with doas privileges |

### Navigation (plugins/init.lua)

| Mode | Key | Action |
|------|-----|--------|
| n | `Ctrl-h/j/k/l` | Move to split/zellij pane (smart-splits) |
| n | `Space ?` | Show buffer-local keymaps (which-key) |
| n | `Space tq` | Toggle quickfix |
| n | `Space tl` | Toggle loclist |
| qf | `>` / `<` | Expand/collapse quickfix context |

### Search (plugins/search.lua)

| Mode | Key | Action |
|------|-----|--------|
| n | `,b` | fzf-lua buffers |
| n | `,/` | fzf-lua live grep |
| n | `,f` | fzf-lua files |
| n | `Space Space` | fzf-lua global picker |
| n | `,d` | fzf-lua diagnostics |
| n | `,r` | fzf-lua resume |
| n | `,gc` | Git buffer commits |
| v | `,gc` | Git commits for selected range |
| n | `,gC` | Git all commits |
| n | `,gb` | Git branches |
| n | `,gs` | Git status |
| n | `,gS` | Git stash |
| fzf | `Alt-p` | Toggle preview |
| fzf | `Ctrl-x` | Open in horizontal split |

### LSP (plugins/lsp.lua)

Neovim 0.12 built-in defaults (not listed): `grn` rename, `grr` references,
`gri` implementation, `gO` document symbols, `gra` code action, `grt` type def,
`grx` codelens run, `Ctrl-S` (insert) signature help, `]d`/`[d` diagnostic nav.

| Mode | Key | Action |
|------|-----|--------|
| n | `Ctrl-]` | Goto definition (native) |
| n | `gD` | Goto declaration |
| n | `gd` | Goto definition (fzf-lua) |
| n | `gvd` / `gxd` / `gtd` | Definition in vsplit / hsplit / tab |
| n | `gvt` / `gxt` / `gtt` | Type definition in vsplit / hsplit / tab |
| n | `gri` | Implementation (fzf-lua override) |
| n | `grvi` / `grxi` / `grti` | Implementation in vsplit / hsplit / tab |
| n | `grr` | References (fzf-lua override) |
| n | `gvr` / `gxr` / `gtr` | References in vsplit / hsplit / tab |
| n | `Space ci` | Incoming calls |
| n | `Space co` | Outgoing calls |
| n | `gO` | Document symbols (fzf-lua override) |
| n | `Space ws` | Workspace symbols |
| n | `Space wd` | Workspace diagnostics |
| n | `Space th` | Toggle inlay hints |
| n,v | `Space f` | Format buffer (conform.nvim) |

### Git (plugins/git.lua)

| Mode | Key | Action |
|------|-----|--------|
| n | `Space go` | Open Neogit |
| n,v | `Space gy` | Copy git permalink |
| n | `]c` / `[c` | Next/prev git change (or diff hunk) |
| n | `Space hs` | Stage hunk |
| n | `Space hr` | Reset hunk |
| v | `Space hs` | Stage hunk (visual) |
| v | `Space hr` | Reset hunk (visual) |
| n | `Space hS` | Stage buffer |
| n | `Space hR` | Reset buffer |
| n | `Space hp` | Preview hunk |
| n | `Space hb` | Blame line |
| n | `Space tb` | Toggle blame line |
| n | `Space hd` | Diff against index |
| n | `Space hD` | Diff against last commit |
| n | `Space hc` | Change base to index |
| n | `Space hC` | Change base to HEAD |
| n | `Space tgd` | Toggle inline deleted |
| n | `Space tgw` | Toggle word diff |
| n | `Space tgl` | Toggle line highlighting |
| o,x | `ih` | Git hunk text object |
| n | `]x` / `[x` | Next/prev git conflict |

### Git Rebase (after/ftplugin/gitrebase.lua)

| Mode | Key | Action |
|------|-----|--------|
| n,v | `gc` | Cycle action |
| n,v | `gp` | Pick |
| n,v | `ge` | Edit |
| n,v | `gf` | Fixup |
| n,v | `gd` | Drop |
| n,v | `gs` | Squash |
| n,v | `gr` | Reword |

### Editing (plugins/editing.lua)

| Mode | Key | Action |
|------|-----|--------|
| n | `Ctrl-a` / `Ctrl-x` | Increment / decrement (dial.nvim) |
| v | `Ctrl-a` / `Ctrl-x` | Increment / decrement (visual) |
| v | `g Ctrl-a` / `g Ctrl-x` | Sequential increment / decrement |
| x | `Space re` | Extract function |
| x | `Space rf` | Extract function to file |
| x | `Space rv` | Extract variable |
| n | `Space rI` | Inline function |
| n,x | `Space ri` | Inline variable |
| n | `Space rb` | Extract block |
| n | `Space rB` | Extract block to file |
| n | `Space rp` | Debug printf |
| n,x | `Space rV` | Debug print variable |
| n | `Space rc` | Cleanup debug statements |

### Treesitter (plugins/treesitter.lua)

| Mode | Key | Action |
|------|-----|--------|
| n,v | `Alt-k` / `Alt-j` | Treewalker up / down |
| n,v | `Alt-h` / `Alt-l` | Treewalker left / right |
| n | `Shift-Alt-k` / `Shift-Alt-j` | Treewalker swap up / down |
| n | `Shift-Alt-h` / `Shift-Alt-l` | Treewalker swap left / right |

### AI (plugins/ai.lua)

| Mode | Key | Action |
|------|-----|--------|
| n | `Space p` | Accept Copilot NES + goto end |
| n | `Esc` | Dismiss Copilot NES |
| i | `Ctrl-f` | Accept Copilot NES (insert mode) |
| n | `Space tc` | Toggle Copilot |

### Completion (plugins/completion.lua)

Uses blink.cmp `cmdline` preset defaults plus:

| Mode | Key | Action |
|------|-----|--------|
| i | `CR` | Accept completion |

### Debug (plugins/debug.lua)

| Mode | Key | Action |
|------|-----|--------|
| n | `Space td` | Toggle debug mode (debugmaster) |

### Runner (plugins/runner.lua)

| Mode | Key | Action |
|------|-----|--------|
| n | `Space to` | Toggle Overseer |
| n | `Space ob` | Build (just build, no prompt) |
| n | `Space oB` | Build (just build, with prompt) |
| n | `Space ot` | Test (just test, no prompt) |
| n | `Space oT` | Test (just test, with prompt) |
| n | `Space of` | Test current file (no prompt) |
| n | `Space oF` | Test current file (with prompt) |
| n | `Space od` | Debug test file (no prompt) |
| n | `Space oD` | Debug test file (with prompt) |
| n | `Space oa` | Autofix |
| n | `Space or` | Run task picker |
| n | `Space os` | Overseer shell |
| n | `Space ol` | Restart last task |

### Autocmds (config/autocmds.lua)

| Filetype | Key | Action |
|----------|-----|--------|
| help, qf, checkhealth, etc. | `q` | Close buffer |

## Zellij

All binds are in `shared_except "locked"` mode (active everywhere except locked mode).

| Key | Action |
|-----|--------|
| `Alt-1` through `Alt-9` | Go to tab N |
| `Alt-t` | New tab |
| `Alt-[` / `Alt-]` | Previous / next tab |
| `Alt-w` | Toggle pane fullscreen |
| `Alt-x` | Close focused pane |
| `Alt-e` | Edit scrollback |
| `Alt-q` | Detach session |
| `Alt--` / `Alt-=` | Resize decrease / increase |
| `Ctrl-h/j/k/l` | Move focus (vim-zellij-navigator) |

## Zsh

Emacs mode (`bindkey -e`) is the base.

### Custom bindings (.zshrc)

| Key | Action |
|-----|--------|
| `Ctrl-U` | Backward kill line |
| `Ctrl-Right` | Forward word |
| `Ctrl-Left` | Backward word |
| `Alt-Right` | Forward word |
| `Alt-Left` | Backward word |
| `Ctrl-Backspace` | Backward kill word |
| `Ctrl-Delete` | Kill word |
| `Ctrl-Z` | Toggle foreground/background |
| `Ctrl-D` | Exit shell (even on non-empty line) |
| `Ctrl-X Ctrl-E` | Edit command in $EDITOR |
| `Ctrl-Y` | Copy command line to clipboard (OSC 52) |
| `.` | Smart dot expansion (.. → ../..) |
| `Shift-Tab` | Accept autosuggestion |
| `Up` / `Down` | History substring search |
| `Ctrl-R` | fzf history search (built-in) |
| `Ctrl-X Ctrl-R` | fzf history search + execute |
| `Ctrl-T` | fzf file picker (built-in) |
| `Alt-C` | fzf cd (built-in) |

## Ghostty

### Unbound (disabled defaults)

| Key | Reason |
|-----|--------|
| `Ctrl-Shift-T` | Zellij handles tabs |
| `Ctrl-Shift-N` | Zellij handles panes |
| `Ctrl-Shift-O` | Unneeded |
| `Ctrl-Shift-Enter` | Zellij handles splits |
| `Ctrl-Shift-PageUp/Down` | Unneeded |

### Custom bindings

| Key | Action |
|-----|--------|
| `Ctrl-Shift-Up` / `Ctrl-Shift-Down` | Scroll one line up / down |
| `Alt-u` | Scroll page up |
| `Alt-d` | Scroll page down |
| `Alt-g` | Scroll to top |
| `Alt-Shift-g` | Scroll to bottom |

## Cross-tool Shared Keys

| Key | Neovim | Zellij | Zsh | Ghostty | Sway |
|-----|--------|--------|-----|---------|------|
| `Ctrl-h/j/k/l` | Split nav (smart-splits) | Pane nav (vim-zellij-navigator) | — | — | — |
| `Alt-h/j/k/l` | Treewalker nav | — | — | — | — |
| `Alt-1..9` | — | Go to tab N | — | — | — |
| `Alt-t` | — | New tab | — | — | — |
| `Alt-q` | — | Detach | — | — | — |
| `Alt-u` | — | — | — | Scroll page up | — |
| `Alt-d` | — | — | — | Scroll page down | — |
| `Super+h/j/k/l` | — | — | — | — | Focus direction |
| `Super+n` | — | — | — | — | Dismiss notification |

## Sway

Mod key: `Super` (Mod4). Only personal additions beyond sway defaults listed.

### Personal keybinds (sway/config)

| Key | Action |
|-----|--------|
| `XF86AudioRaiseVolume` | Volume +5% |
| `XF86AudioLowerVolume` | Volume -5% |
| `XF86AudioMute` | Mute toggle |
| `Super+m` | Mic mute toggle |
| `Super+Shift+m` | Speaker mute toggle |
| `XF86AudioPlay` | Play/pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |
| `Print` | Region screenshot (grim+slurp) |
| `Shift+Print` | Full screenshot (grim) |
| `Super+Shift+s` | Lock screen + pause media |
| `Super+n` | Dismiss notification |
| `Super+Shift+n` | Dismiss all notifications |
| `Super+Tab` | Next workspace |
| `Super+Shift+Tab` | Previous workspace |
| `F7` | Toggle display mode (laptop-off/side-by-side) |
