# Shared Agent Instructions

The `canonical` role deploys `dot_codex/AGENTS.md` to `~/.codex/AGENTS.md`.
The other instruction files are symbolic links to that file:

| Agent       | User instruction file                |
| ----------- | ------------------------------------ |
| Codex       | `~/.codex/AGENTS.md`                 |
| Claude Code | `~/.claude/CLAUDE.md`                |
| OpenCode    | `~/.config/opencode/AGENTS.md`       |
| Hermes      | `~/.hermes/SOUL.md`                  |
| OMP         | `~/.omp/agent/AGENTS.md`             |
| Copilot CLI | `~/.copilot/copilot-instructions.md` |

Run `just apply` on the target machine, then start new agent sessions. Edit
`dot_codex/AGENTS.md` to change the shared instructions. The root `AGENTS.md`
contains instructions for this repository and is not deployed as a user file.

The deployment test checks the managed paths and link targets. It does not
test a live model session. Custom agent home directories, disabled instruction
loading, and project instructions can change which rules an agent receives.

The shared policy assigns planning and integration to a strong default model,
bounded summaries and simple tasks to cheaper agents, and difficult consultations
to the strongest available model. It is an instruction policy, not a model
router. It does not change provider accounts, model settings, or spending limits.

See the upstream guides for [Codex](https://developers.openai.com/codex/guides/agents-md/),
[Claude Code](https://code.claude.com/docs/en/memory),
[OpenCode](https://opencode.ai/docs/rules/),
[Hermes](https://hermes-agent.nousresearch.com/docs/user-guide/which-file-does-what),
and [Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions).
