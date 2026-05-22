---
name: tuicr
description: Review local git changes with tuicr TUI via zellij floating pane
---

# tuicr - TUI Change Reviewer

Launch the `tuicr` TUI tool in a zellij floating pane to interactively review
local git changes.

## Usage

```
/tuicr [directory]
```

Or simply mention wanting to review changes with tuicr.

## How It Works

Since coding agents cannot run interactive TUI applications directly, this
skill uses a zellij workaround:

1. Detects if the current agent session is running inside zellij (`$ZELLIJ`).
2. If yes: opens tuicr in a floating pane, blocks until it exits, then reads
   any exported instructions back from a temp file.
3. If no: instructs the user to restart the agent inside zellij.

## Determining the Directory

**Important:** You must determine the correct git repository directory based on
context.

Consider:

- The user's current working directory
- Any repository they've been working in during the session
- Explicit directory mentioned in their request
- The git status output if available

Common patterns:

- "review my changes" → use current working directory
- "review changes in myproject" → find that repo path
- After editing files → use the directory of those files

## Workflow

1. **Determine target directory** (cwd, recent file ops, ask if ambiguous).

2. **Run the wrapper** with a 10-minute timeout:

   ```bash
   <skill-directory>/tuicr-wrapper.sh [directory]
   ```

   **IMPORTANT:** Always set `timeout: 600000` (10 minutes) on the Bash tool
   call. The script blocks on a FIFO until tuicr exits; without the extended
   timeout the agent may background it after 2 minutes.

3. **Handle the result**:
   - Success → tuicr opened in a floating pane, user reviewed and exited.
   - Not in zellij → relay the instructions to the user.
   - Not a git repo → ask for the correct path.

4. **Process instructions from tuicr output**:

   ```
   === TUICR INSTRUCTIONS ===
   <instructions here>
   === END TUICR INSTRUCTIONS ===
   ```

   If present, parse and execute them. If absent, ask the user to paste from
   clipboard.

## Configuration

| Variable          | Default    | Description                                    |
| ----------------- | ---------- | ---------------------------------------------- |
| `TUICR_PANE_MODE` | `floating` | `floating` (overlay) or `split` (horizontal)   |
| `TUICR_SPLIT_DIR` | `down`     | When `split`: `down`, `up`, `right`, or `left` |

Example:

```bash
TUICR_PANE_MODE=split TUICR_SPLIT_DIR=down \
  <skill-directory>/tuicr-wrapper.sh /path/to/repo
```

## Zellij Tips (relay to user if needed)

- Move focus between panes: `Alt-h/j/k/l`
- Close the floating pane: press `q` inside tuicr (pane auto-closes)
- Toggle floating pane visibility: `Ctrl-p` then `w`
- Zoom current pane: `Ctrl-p` then `f`

## Error Handling

| Error               | Action                                                                                               |
| ------------------- | ---------------------------------------------------------------------------------------------------- |
| Not in zellij       | Tell the user to restart the agent inside zellij                                                     |
| Not a git repo      | Ask user for correct directory                                                                       |
| tuicr not installed | Tell user `tuicr` is provisioned via nix; run `home-manager switch` (VM) or `just nix-switch` (host) |

## When NOT to use

- User just wants `git diff` output (use git directly)
- Reviewing remote/PR changes (use `gh` CLI or web)
- User explicitly asks for non-interactive review
