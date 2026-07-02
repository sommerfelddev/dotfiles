# Global Agent Instructions

These rules apply across repositories. Merge them with any repo-specific
`AGENTS.md` files, and let the more specific repo instructions win when they
conflict.

## Core Behavior

Think before changing files.

- State assumptions when they matter.
- If the request has multiple plausible meanings, name the options instead of
  picking silently.
- If a simpler approach exists, say so.
- If something is unclear enough to change the outcome, ask before editing.

Prefer simple, direct solutions.

- Implement the requested behavior, not adjacent features.
- Do not add abstractions for one use.
- Do not add configurability, fallback behavior, or broad error handling unless
  the task needs it.
- If the solution is getting large, stop and look for the smaller shape.

Make surgical changes.

- Touch only the files needed for the task.
- Match the existing style and local patterns.
- Clean up unused code that your change creates.
- Mention unrelated dead code or stale comments instead of deleting them unless
  the user asks.

Work toward a verifiable goal.

- Define the success criteria before implementation.
- For multi-step work, keep a short plan with checks.
- Loop until the result is implemented and verified, or clearly report the
  blocker.

## Environment And Tooling

Prefer repo-owned workflows over ad hoc commands.

- If a repo has a `justfile`, start with `just --list`.
- Use `just` recipes for build, test, format, lint, deploy, and maintenance
  workflows when they exist.
- If a recipe is broken, fix it or flag the gap. Do not bypass it silently.
- If a common workflow has no recipe, propose adding one before building a
  manual workflow around it.

When running inside `aibox`:

- Treat the current working directory as the project workspace and the only
  intended writable project tree.
- Network access may be available, but broad host home and config state may not
  be mounted.
- Do not run `chezmoi apply`, `just apply`, or other commands that deploy
  dotfiles into `$HOME` or system paths. Prepare and validate the source
  changes, then tell the user which deployment command to run outside the
  sandbox.
- Do not install tools globally with apt, brew, npm global installs, pipx,
  cargo install, or similar tools unless explicitly asked.
- When a tool is missing, add it declaratively to the project's Nix devShell,
  then use `direnv reload` or `nix develop` as appropriate.
- If the project has no `.envrc` and no Nix devShell, bootstrap a minimal
  `flake.nix` devShell and an `.envrc` containing `use flake`; run
  `direnv allow` once before adding tools.
- Keep tooling changes in project files such as `flake.nix`, `shell.nix`,
  `devshell.nix`, or the existing local equivalent.
- Treat generic `$HOME` cache, config, and local writes as sandbox-private
  unless a path is explicitly mounted by `aibox`.
- Run `aibox -p` or `aibox --dump-prompt` again when the sandbox rules need to
  be refreshed.

## Commits And History

Make commits atomic, single-concern, and independently reviewable.

- Before staging, ask whether the commit can be smaller and still make sense.
- Each commit should pass the relevant checks for the change at the HEAD of that
  commit.
- Do not create commits that only make sense when paired with a later commit.
- Never run `git push`.

Commit messages:

- Use a short imperative subject.
- Use the body only for non-obvious context the diff cannot supply.
- Keep the body to at most four lines.
- Leave the body empty when the subject is enough.
- Do not restate the diff, include exact generated counts, list future work, or
  give per-file and per-test breakdowns.

When splitting refactors:

- Split by reviewable concern even if the same file is touched in multiple
  places.
- Stage source changes per commit.
- Bundle bulk generated artifacts with the final commit of that phase.

When addressing review:

- Prefer `git commit --amend` or `git rebase -i` with `reword` or `edit`.
- Do not use `git reset --soft` to rebuild a commit chain by hand.
- Rerun checks only for code or config that actually changed.

## Public-Facing Prose

This applies to commit messages, code comments, docs, PR descriptions, and any
text that lands in a repo.

- Write contract comments only: accepted inputs, returned outputs, observable
  behavior, and constraints.
- If a name and signature already explain the contract, omit the comment.
- Remove filler, redundancy, future-work notes, and commentary about the edit.
- Avoid rhetorical tics: "not X, but Y", stacked fragments, stylistic em dashes,
  and unnecessary bullet lists.
- Delete common AI phrasing such as "load-bearing", "material finding", and
  "it is not just X, it is Y".
- Read important prose out loud. If it sounds generated, rewrite it plainly.

## Coding Tasks Only

These rules apply when changing application or library code. They do not apply
to routine dotfile maintenance, package lists, deployment manifests, or
comment-only changes unless the task includes real code behavior.

Functions:

- Prefer small, single-purpose functions.
- Treat roughly 15 lines as a soft target, not a hard limit.
- Keep one level of abstraction inside a function.
- Extract helpers when a function mixes intent-level steps with low-level
  mechanics.

API design:

- Make invalid states unrepresentable where the language and local style allow
  it.
- When two mutations must happen together, expose one API that performs the
  whole sequence.
- Prefer scope guards, RAII, callbacks, or single transaction-style methods over
  "call X then Y" protocols.
- Abstract repeated 3 to 6 line patterns after they recur across several sites
  in the same change. Do not pre-abstract for one or two uses.

Testing:

- For behavior changes, prefer red, green, refactor within each commit.
- First add or adjust a test that fails for the intended reason.
- Then write the minimum code that makes it pass.
- Then clean up structure while checks stay green.
- Skip TDD only with a stated reason, such as documentation-only changes,
  mechanical moves, config-only changes, or initial build/tooling scaffolding.
