# Claude in Pi

You are inside Pi, regardless of which model generates this turn. Claude models under `claude-bridge/` run through Claude Code's Agent SDK; their tool calls flow through Pi and remain visible in its terminal.

## Delegation

Use Pi's `subagent` tool only when the operator or applicable project instructions authorize delegation. First inspect `subagent({action:"list", capabilities:true})`; for model overrides inspect `subagent({action:"models"})` and copy an exact provider/model ID. Read the installed workflow/tool-reference guide before multi-step orchestration. Use one top-level `async:true` workflow for parallel or multi-step delegation, fresh-context independent reviewers, and isolated concurrent writers. Observe child results at dependency barriers.

Use native Pi children rather than Claude Code's Task tool or shell-launched `pi -p`/`claude -p` helpers. Those bypass the fleet and its supervision. The installed chat auto-namer is a separate, bounded, no-tools title query, not a coding helper.

The fleet is above the editor; `/subagents-fleet` opens live transcripts. `toolActivation:"eager"` exposes `subagent` from the first request. If it is absent, inspect activation/allowlists and use `subagents_enable` if available before claiming the package is missing.

Any supported parent model can launch a Claude child using an exact `claude-bridge/<model>` ID, with effort selected using the model's thinking suffix. Children default to fresh context: supply the task, paths, constraints, and acceptance criteria. The bridge and this instruction loader are explicitly in `subagents.defaultSubagentOnlyExtensions`, so foreground and background children capture their own prompts.

Treat child launch, extension, workflow, or prompt-capture failures as infrastructure blockers. Report the exact run/status/error and cwd/branch, preserve partial changes, and ask before changing execution protocols. A delivered steer is not proof the child complied. Ordinary async children notify the session natively: return control instead of polling or sleeping. Use supervisor dialogue for blocked decisions.

## Claude authentication and prompt compatibility

The bridge uses Claude Code's own subscription login, separate from Pi's `/login`. This workstation profile records a Max plan; model/context availability still depends on the actual account and installed catalog. AskClaude is disabled; authorized helpers use `subagent`.

Launch subscription-backed Pi without exported `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, or `ANTHROPIC_BASE_URL`: these redirect the Claude Code child and can break every turn. Keep credentials outside this repository.

Claude Code hooks also run inside bridge turns. A Claude-only hook can skip them with `[ -n "$PI_CODING_AGENT" ] && exit 0`.

Add prompt instructions through `systemPromptOptions.sections`, appended instructions, or messages. Preserve Pi's structured prompt; wholesale `systemPrompt`/`forceSystemPrompt` replacement can cause `prompt-capture` rejection. This loader reads instruction files once. Start a new session after changing them.

Abort, compaction, tree navigation, errors, and reopening a session can rebuild Claude Code history and miss the prompt cache. Avoid unnecessary abort/retry cycles. A Claude process serves a turn, not a permanent idle worker.
