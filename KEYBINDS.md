# Custom Keybinds Reference

All non-default keybinds across neovim, zellij, zsh, ghostty, and sway.

## Neovim

Leader: `Space` | Local leader: `,`

### General (config/keymaps.lua)

| Mode | Key          | Action                              |
| ---- | ------------ | ----------------------------------- |
| n    | `Esc`        | Clear search highlight              |
| n    | `gV`         | Select last inserted text           |
| n    | `↓` / `↑`    | Scroll viewport (C-e / C-y)         |
| v    | `p`          | Paste without clobbering register   |
| n    | `,s`         | Find and replace (whole file)       |
| v    | `,s`         | Find and replace (selection)        |
| n    | `Space x`    | Write all buffers                   |
| n    | `Space z`    | Write all and quit                  |
| n    | `Space q`    | Quit all                            |
| t    | `Esc Esc`    | Exit terminal mode                  |
| n    | `[w` / `]w`  | Prev/next warning+ diagnostic       |
| n    | `[e` / `]e`  | Prev/next error diagnostic          |
| n    | `yp`         | Yank current file path to clipboard |
|      | `:SudoWrite` | Write file with sudo privileges     |

### Navigation (plugins/init.lua)

| Mode | Key            | Action                                   |
| ---- | -------------- | ---------------------------------------- |
| n    | `Ctrl-h/j/k/l` | Move to split/zellij pane (smart-splits) |
| n    | `Space ?`      | Show buffer-local keymaps (which-key)    |
| n    | `Space tq`     | Toggle quickfix                          |
| n    | `Space tl`     | Toggle loclist                           |
| qf   | `>` / `<`      | Expand/collapse quickfix context         |

### Search (plugins/search.lua)

| Mode | Key           | Action                         |
| ---- | ------------- | ------------------------------ |
| n    | `,b`          | fzf-lua buffers                |
| n    | `,/`          | fzf-lua live grep              |
| n    | `,f`          | fzf-lua files                  |
| n    | `Space Space` | fzf-lua global picker          |
| n    | `,d`          | fzf-lua diagnostics            |
| n    | `,r`          | fzf-lua resume                 |
| n    | `,gc`         | Git buffer commits             |
| v    | `,gc`         | Git commits for selected range |
| n    | `,gC`         | Git all commits                |
| n    | `,gb`         | Git branches                   |
| n    | `,gs`         | Git status                     |
| n    | `,gS`         | Git stash                      |
| fzf  | `Alt-p`       | Toggle preview                 |
| fzf  | `Ctrl-x`      | Open in horizontal split       |

### LSP (plugins/lsp.lua)

Neovim 0.12 built-in defaults (not listed): `grn` rename, `grr` references,
`gri` implementation, `gO` document symbols, `gra` code action, `grt` type def,
`grx` codelens run, `Ctrl-S` (insert) signature help, `]d`/`[d` diagnostic nav.

| Mode | Key                      | Action                                   |
| ---- | ------------------------ | ---------------------------------------- |
| n    | `Ctrl-]`                 | Goto definition (native)                 |
| n    | `gD`                     | Goto declaration                         |
| n    | `gd`                     | Goto definition (fzf-lua)                |
| n    | `gvd` / `gxd` / `gtd`    | Definition in vsplit / hsplit / tab      |
| n    | `gvt` / `gxt` / `gtt`    | Type definition in vsplit / hsplit / tab |
| n    | `gri`                    | Implementation (fzf-lua override)        |
| n    | `grvi` / `grxi` / `grti` | Implementation in vsplit / hsplit / tab  |
| n    | `grr`                    | References (fzf-lua override)            |
| n    | `gvr` / `gxr` / `gtr`    | References in vsplit / hsplit / tab      |
| n    | `Space ci`               | Incoming calls                           |
| n    | `Space co`               | Outgoing calls                           |
| n    | `gO`                     | Document symbols (fzf-lua override)      |
| n    | `Space ws`               | Workspace symbols                        |
| n    | `Space wd`               | Workspace diagnostics                    |
| n    | `Space th`               | Toggle inlay hints                       |
| n,v  | `Space f`                | Format buffer (conform.nvim)             |

### Git (plugins/git.lua)

| Mode | Key         | Action                              |
| ---- | ----------- | ----------------------------------- |
| n    | `Space go`  | Open Neogit                         |
| n,v  | `Space gy`  | Copy git permalink                  |
| n    | `]c` / `[c` | Next/prev git change (or diff hunk) |
| n    | `Space hs`  | Stage hunk                          |
| n    | `Space hr`  | Reset hunk                          |
| v    | `Space hs`  | Stage hunk (visual)                 |
| v    | `Space hr`  | Reset hunk (visual)                 |
| n    | `Space hS`  | Stage buffer                        |
| n    | `Space hR`  | Reset buffer                        |
| n    | `Space hp`  | Preview hunk                        |
| n    | `Space hb`  | Blame line                          |
| n    | `Space tb`  | Toggle blame line                   |
| n    | `Space hd`  | Diff against index                  |
| n    | `Space hD`  | Diff against last commit            |
| n    | `Space hc`  | Change base to index                |
| n    | `Space hC`  | Change base to HEAD                 |
| n    | `Space tgd` | Toggle inline deleted               |
| n    | `Space tgw` | Toggle word diff                    |
| n    | `Space tgl` | Toggle line highlighting            |
| o,x  | `ih`        | Git hunk text object                |
| n    | `]x` / `[x` | Next/prev git conflict              |

### Git Rebase (after/ftplugin/gitrebase.lua)

| Mode | Key  | Action       |
| ---- | ---- | ------------ |
| n,v  | `gc` | Cycle action |
| n,v  | `gp` | Pick         |
| n,v  | `ge` | Edit         |
| n,v  | `gf` | Fixup        |
| n,v  | `gd` | Drop         |
| n,v  | `gs` | Squash       |
| n,v  | `gr` | Reword       |

### Editing (plugins/editing.lua)

| Mode | Key                     | Action                            |
| ---- | ----------------------- | --------------------------------- |
| n    | `Ctrl-a` / `Ctrl-x`     | Increment / decrement (dial.nvim) |
| v    | `Ctrl-a` / `Ctrl-x`     | Increment / decrement (visual)    |
| v    | `g Ctrl-a` / `g Ctrl-x` | Sequential increment / decrement  |
| x    | `Space re`              | Extract function                  |
| x    | `Space rf`              | Extract function to file          |
| x    | `Space rv`              | Extract variable                  |
| n    | `Space rI`              | Inline function                   |
| n,x  | `Space ri`              | Inline variable                   |
| n    | `Space rb`              | Extract block                     |
| n    | `Space rB`              | Extract block to file             |
| n    | `Space rp`              | Debug printf                      |
| n,x  | `Space rV`              | Debug print variable              |
| n    | `Space rc`              | Cleanup debug statements          |

### Treesitter (plugins/treesitter.lua)

| Mode | Key                           | Action                       |
| ---- | ----------------------------- | ---------------------------- |
| n,v  | `Alt-k` / `Alt-j`             | Treewalker up / down         |
| n,v  | `Alt-h` / `Alt-l`             | Treewalker left / right      |
| n    | `Shift-Alt-k` / `Shift-Alt-j` | Treewalker swap up / down    |
| n    | `Shift-Alt-h` / `Shift-Alt-l` | Treewalker swap left / right |

### AI (plugins/ai.lua)

| Mode | Key        | Action                           |
| ---- | ---------- | -------------------------------- |
| n    | `Space p`  | Accept Copilot NES + goto end    |
| n    | `Esc`      | Dismiss Copilot NES              |
| i    | `Ctrl-f`   | Accept Copilot NES (insert mode) |
| n    | `Space tc` | Toggle Copilot                   |

### Completion (plugins/completion.lua)

Uses blink.cmp `cmdline` preset defaults plus:

| Mode | Key  | Action            |
| ---- | ---- | ----------------- |
| i    | `CR` | Accept completion |

### Debug (plugins/debug.lua)

| Mode | Key        | Action                          |
| ---- | ---------- | ------------------------------- |
| n    | `Space td` | Toggle debug mode (debugmaster) |

### Runner (plugins/runner.lua)

| Mode | Key        | Action                          |
| ---- | ---------- | ------------------------------- |
| n    | `Space to` | Toggle Overseer                 |
| n    | `Space ob` | Build (just build, no prompt)   |
| n    | `Space oB` | Build (just build, with prompt) |
| n    | `Space ot` | Test (just test, no prompt)     |
| n    | `Space oT` | Test (just test, with prompt)   |
| n    | `Space of` | Test current file (no prompt)   |
| n    | `Space oF` | Test current file (with prompt) |
| n    | `Space od` | Debug test file (no prompt)     |
| n    | `Space oD` | Debug test file (with prompt)   |
| n    | `Space oa` | Autofix                         |
| n    | `Space or` | Run task picker                 |
| n    | `Space os` | Overseer shell                  |
| n    | `Space ol` | Restart last task               |

### Autocmds (config/autocmds.lua)

| Filetype                    | Key | Action       |
| --------------------------- | --- | ------------ |
| help, qf, checkhealth, etc. | `q` | Close buffer |

## Zellij

All binds are in `shared_except "locked"` mode (active everywhere except locked mode).

| Key                     | Action                            |
| ----------------------- | --------------------------------- |
| `Alt-1` through `Alt-9` | Go to tab N                       |
| `Alt-t`                 | New tab                           |
| `Alt-[` / `Alt-]`       | Previous / next tab               |
| `Alt-\`                 | Cycle swap layouts (reset sizes)  |
| `Alt-w`                 | Toggle pane fullscreen            |
| `Alt-x`                 | Close focused pane                |
| <code>Alt-&#124;</code> | Vertical split (new pane right)   |
| `Alt-_`                 | Horizontal split (new pane below) |
| `Alt-e`                 | Edit scrollback                   |
| `Alt-q`                 | Detach session                    |
| `Alt--` / `Alt-=`       | Resize decrease / increase        |
| `Ctrl-h/j/k/l`          | Move focus (vim-zellij-navigator) |
| `Alt-Shift-P`           | Enter Pane mode                   |
| `Alt-Shift-T`           | Enter Tab mode                    |
| `Alt-Shift-R`           | Enter Resize mode                 |
| `Alt-Shift-S`           | Enter Scroll mode                 |
| `Alt-Shift-O`           | Enter Session mode                |
| `Alt-Shift-Z`           | Enter Locked mode                 |
| `Alt-Shift-Q`           | Quit zellij                       |

Mode-entry keys are relocated from their zellij defaults (`Ctrl-p/t/r/s/o/g/q`, `Ctrl-b` TMUX dropped) to `Alt-Shift-*` so the `Ctrl-*` keys pass through to zsh and nvim. Only `Ctrl-h/j/k/l` remain intercepted (for pane navigation).

## Zsh

Emacs mode (`bindkey -e`) is the base.

### Custom bindings (.zshrc)

| Key              | Action                                   |
| ---------------- | ---------------------------------------- |
| `Ctrl-U`         | Backward kill line                       |
| `Ctrl-Right`     | Forward word                             |
| `Ctrl-Left`      | Backward word                            |
| `Alt-Right`      | Forward word                             |
| `Alt-Left`       | Backward word                            |
| `Ctrl-Backspace` | Backward kill word                       |
| `Ctrl-Delete`    | Kill word                                |
| `Ctrl-Z`         | Toggle foreground/background             |
| `Ctrl-D`         | Exit shell (even on non-empty line)      |
| `Ctrl-X Ctrl-E`  | Edit command in $EDITOR                  |
| `Ctrl-Y`         | Copy command line to clipboard (OSC 52)  |
| `.`              | Smart dot expansion (.. → ../..)         |
| `Shift-Tab`      | Accept autosuggestion                    |
| `Up` / `Down`    | History substring search                 |
| `Ctrl-R`         | fzf history search (built-in)            |
| `Ctrl-X Ctrl-R`  | fzf history search + execute             |
| `Ctrl-T`         | fzf file picker (built-in)               |
| `Alt-C`          | fzf cd (built-in)                        |
| `Alt-Shift-Y`    | Copy last command's output (zellij only) |

## Ghostty

### Unbound (disabled defaults)

| Key                | Reason                |
| ------------------ | --------------------- |
| `Ctrl-Shift-T`     | Zellij handles tabs   |
| `Ctrl-Shift-N`     | Zellij handles panes  |
| `Ctrl-Shift-O`     | Unneeded              |
| `Ctrl-Shift-Enter` | Zellij handles splits |

### Custom bindings

| Key                                 | Action                             |
| ----------------------------------- | ---------------------------------- |
| `Ctrl-Shift-Up` / `Ctrl-Shift-Down` | Scroll one line up / down          |
| `Ctrl-Shift-u`                      | Copy URL under cursor to clipboard |
| `Alt-u`                             | Scroll page up                     |
| `Alt-d`                             | Scroll page down                   |
| `Alt-g`                             | Scroll to top                      |
| `Alt-Shift-g`                       | Scroll to bottom                   |

## Yazi

Only non-default keybinds listed. See `yazi --help` for built-in keys.

| Key   | Action                     |
| ----- | -------------------------- |
| `!`   | Open shell here (blocking) |
| `g r` | Go to git root             |
| `g .` | Go to dotfiles             |
| `g x` | Go to doxfiles             |
| `g s` | Go to sync                 |
| `g S` | Go to screenshots          |

Shell: `y` function wraps yazi with cd-on-exit.

## Cross-tool Shared Keys

| Key             | Neovim                   | Zellij                          | Zsh | Ghostty          | Sway                 |
| --------------- | ------------------------ | ------------------------------- | --- | ---------------- | -------------------- |
| `Ctrl-h/j/k/l`  | Split nav (smart-splits) | Pane nav (vim-zellij-navigator) | —   | —                | —                    |
| `Alt-h/j/k/l`   | Treewalker nav           | —                               | —   | —                | —                    |
| `Alt-1..9`      | —                        | Go to tab N                     | —   | —                | —                    |
| `Alt-t`         | —                        | New tab                         | —   | —                | —                    |
| `Alt-q`         | —                        | Detach                          | —   | —                | —                    |
| `Alt-u`         | —                        | —                               | —   | Scroll page up   | —                    |
| `Alt-d`         | —                        | —                               | —   | Scroll page down | —                    |
| `Super+h/j/k/l` | —                        | —                               | —   | —                | Focus direction      |
| `Super+n`       | —                        | —                               | —   | —                | Dismiss notification |

## Sway

Mod key: `Super` (Mod4). Only personal additions beyond sway defaults listed.

### Personal keybinds (sway/config)

| Key                     | Action                                                        |
| ----------------------- | ------------------------------------------------------------- |
| `XF86AudioRaiseVolume`  | Volume +5%                                                    |
| `Super+Ctrl+k`          | Volume +5% (non-XF86 alt)                                     |
| `XF86AudioLowerVolume`  | Volume -5%                                                    |
| `Super+Ctrl+j`          | Volume -5% (non-XF86 alt)                                     |
| `XF86AudioMute`         | Mute toggle                                                   |
| `Super+m`               | Mic mute toggle                                               |
| `Super+Shift+m`         | Speaker mute toggle                                           |
| `XF86AudioPlay`         | Play/pause                                                    |
| `Super+Ctrl+space`      | Play/pause (non-XF86 alt)                                     |
| `XF86AudioNext`         | Next track                                                    |
| `Super+Ctrl+l`          | Next track (non-XF86 alt)                                     |
| `XF86AudioPrev`         | Previous track                                                |
| `Super+Ctrl+h`          | Previous track (non-XF86 alt)                                 |
| `XF86MonBrightnessUp`   | Brightness +5% (brightnessctl)                                |
| `Super+Ctrl+]`          | Brightness +5% (non-XF86 alt)                                 |
| `XF86MonBrightnessDown` | Brightness -5% (brightnessctl)                                |
| `Super+Ctrl+[`          | Brightness -5% (non-XF86 alt)                                 |
| `XF86AudioMicMute`      | Mic mute toggle                                               |
| `XF86Bluetooth`         | Bluetooth power toggle (bluetoothctl)                         |
| `XF86ScreenSaver`       | Lock screen + pause media (same as Super+Shift+s)             |
| `XF86Sleep`             | Suspend system (systemctl suspend)                            |
| `XF86WLAN`              | Toggle Wi-Fi (rfkill)                                         |
| `XF86RFKill`            | Toggle all radios (rfkill)                                    |
| `Super+Shift+Return`    | Open ghostty with yazi (file manager)                         |
| `Super+Shift+b`         | Launch librewolf                                              |
| `Super+Shift+t`         | Floating nvim with a fresh scratch txt under $XDG_RUNTIME_DIR |
| `Super+c`               | Floating ipython REPL (quick calculator / scratch python)     |
| `Print`                 | Region screenshot (grim+slurp)                                |
| `Shift+Print`           | Full screenshot (grim)                                        |
| `Super+i`               | Dictate toggle (whisper.cpp → wtype + clipboard)              |
| `Super+Shift+o`         | OCR region (tesseract → clipboard)                            |
| `Super+Shift+s`         | Lock screen + pause media                                     |
| `Super+n`               | Dismiss visible notification (also marks it seen)             |
| `Super+Shift+n`         | Dismiss all visible notifications (mark all seen)             |
| `Super+Ctrl+n`          | Restore last dismissed; pop it back into the pending set      |
| `XF86Favorites`         | Notification history picker (Enter copies + dismisses)        |
| `Super+p`               | Clipboard history picker (wofi; Enter pastes, Alt-d deletes)  |
| `Super+Shift+p`         | Clipboard history delete entry (Enter deletes)                |
| `Super+period`          | Emoji picker (bemoji → wofi; types + copies)                  |
| `Super+Tab`             | Next workspace                                                |
| `Super+Shift+Tab`       | Previous workspace                                            |
| `Super+]`               | Focus next window in container (monocle cycling)              |
| `Super+[`               | Focus prev window in container (monocle cycling)              |
| `XF86Display`           | Toggle display mode (laptop-off/side-by-side)                 |
| `XF86Tools`             | Floating pulsemixer (audio mixer TUI)                         |
| `XF86Keyboard`          | Floating glow pager for `~/dotfiles/KEYBINDS.md`              |
| `Super+z` then `w`      | Display QR for clipboard (wqr)                                |
| `Super+z` then `r`      | Scan QR via webcam, copy to clipboard (rqr)                   |
| `Super+t`               | Toggle Thunderbird (tiled on current workspace)               |

### System submode (sway/config)

`Super+x` enters `mode "system"` (mode name shown in waybar). One letter
runs the action and exits the mode; `Escape` or `Return` exits without
acting. Provides non-XF86 access to the rare hardware toggles and TUI
launchers.

| In `system` mode  | XF86 equivalent | Action                      |
| ----------------- | --------------- | --------------------------- |
| `b`               | `XF86Bluetooth` | Bluetooth power toggle      |
| `w`               | `XF86WLAN`      | Wi-Fi toggle (rfkill wifi)  |
| `r`               | `XF86RFKill`    | Toggle all radios (rfkill)  |
| `s`               | `XF86Sleep`     | Suspend (systemctl suspend) |
| `d`               | `XF86Display`   | Display mode toggle         |
| `v`               | `XF86Tools`     | Floating pulsemixer         |
| `k`               | `XF86Keyboard`  | Floating glow KEYBINDS.md   |
| `m`               | `XF86Favorites` | mako notification history   |
| `Escape`/`Return` | —               | exit submode                |

## Typing / Input

Layout: `us(altgr-intl)` with Caps→Esc and Right Ctrl as Compose
(`xkb_options caps:escape,compose:rctrl`). Normal `'` `"` `` ` `` `~` `^`
behave as-is; accents only fire through AltGr or Compose.

### AltGr (Right Alt) — one or two keystrokes

| Keys             | Output                        |
| ---------------- | ----------------------------- |
| `AltGr+5`        | `€`                           |
| `AltGr+'` then v | `á é í ó ú ý` (dead acute)    |
| `AltGr+~` then v | `ã õ ñ` (dead tilde)          |
| `AltGr+^` then v | `â ê î ô û` (dead circumflex) |
| `` AltGr+` `` v  | `à è ì ò ù` (dead grave)      |
| `AltGr+,` then c | `ç` (dead cedilla)            |
| `AltGr+Shift+1`  | `¡`                           |
| `AltGr+Shift+/`  | `¿`                           |
| `AltGr+s`        | `ß`                           |

Capitals: hold Shift while pressing the target letter (`AltGr+'` then
`Shift+a` → `Á`).

### Compose (Right Ctrl) — discoverable, extensible

Standard sequences from the system Compose table plus custom PT-PT extras
in `~/.XCompose`. Press and release Compose, then the sequence.

| Sequence        | Output          |
| --------------- | --------------- |
| `Compose ' a`   | `á` (any vowel) |
| `Compose ~ a`   | `ã` / `õ` / `ñ` |
| `Compose ^ a`   | `â` / `ê` / `ô` |
| `Compose , c`   | `ç`             |
| `Compose < <`   | `«` (PT-PT)     |
| `Compose > >`   | `»` (PT-PT)     |
| `Compose = e`   | `€`             |
| `Compose o _`   | `º`             |
| `Compose a _`   | `ª`             |
| `Compose - - -` | `—` (em dash)   |
| `Compose - - .` | `–` (en dash)   |
| `Compose . . .` | `…`             |
