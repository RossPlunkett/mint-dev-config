# Recorded Pi workstation profile

This directory is the portable source of truth for Felix's Pi customizations, inventoried from the active machine on 2026-10-08. `settings.json`, `subagents.json`, and `claude-bridge.json` hold the actual preferences; `package.json` lists bundled resources. Authentication, device IDs, cached model catalogs, sessions, run history, missions, and logs are intentionally absent.

## Install or restore

Full workstation bootstrap installs Node/Claude Code/Pi and runs `scripts/install-pi.sh`. For Pi alone on Linux:

```bash
# Preferred upstream managed install (pins transitive dependencies):
curl -fsSL https://pi.dev/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
pi --version
# Node 22.19+ is required; the upstream installer can provision it.
# Alternative with an existing Node installation:
# npm install -g --ignore-scripts @earendil-works/pi-coding-agent@1.1.0
npm install -g @anthropic-ai/claude-code
./scripts/install-pi.sh
pi list
cd /path/to/your/project
pi
```

The tested baseline is **Pi 1.1.0**, **pi-claude-bridge 0.9.2**, **pi-subagents 0.76.1**, and **pi-omp-theme 1.0.15**. The profile installer accepts Pi 1.1.0+ and installs these extension pins, merging recorded preferences over existing settings while retaining unrelated keys/packages. It backs up changed config under `~/.config-backups/pi-*`; it does not copy or modify auth/session databases. It honors `PI_CODING_AGENT_DIR` when set. Rerun to restore preferences. This intentionally reapplies the recorded model/theme/trust/authority choices, not just missing defaults.

The local Pi package is loaded **from this checkout**. Keep it in place. After moving it, rerun the installer from its new location and retire the old local package entry with `pi remove /old/path/pi`. A known `new-agent-office/deploy/container/pi` package entry and the previous standalone `extensions/chat-title.ts` widget are retired to avoid duplicate resources; arbitrary custom extensions remain your responsibility.

Current machine: `~/.local/bin/pi` points to `~/.pi/agent/bin/pi`, which selects a managed release from `~/.pi/agent/install/current-version`, prepends installer-owned Node from `~/.local/share/pi-node/current/bin`, and preserves the caller's cwd. Use **`pi update`** for that managed install; use npm for an npm-installed Pi. Do not copy release binaries or launchers tied to a removed NVM version. `type -a pi` helps diagnose PATH shadowing.

## Authentication and model selection

- Run Claude Code and complete its subscription sign-in. The bridge uses **Claude Code's login**, not Pi's Anthropic `/login`. This profile records `provider.plan: max`; select the actual plan on other accounts. A Max setting does not grant a subscription or guarantee every model's context size.
- Run Pi's `/login` for OpenAI or another native provider. The recorded startup model is `openai/gpt-6.1-sol` with medium thinking. If unavailable for that account/catalog, select an available exact ID through `/model` and update your local defaults; no custom gateway/model endpoint is bundled.
- Bridge models appear under `claude-bridge/`, for example Opus/Sonnet/Haiku. Inspect `/model` or subagents' `action:"models"` rather than assuming a historical ID is still available.
- Subscription-backed launches must not inherit `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, or `ANTHROPIC_BASE_URL`. For a one-off clean launch: `env -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_BASE_URL pi`. Do not globally erase credentials used by other tools.
- AskClaude stays disabled. The bridge's strict MCP and auto-memory defaults are not overridden. Hooks in `~/.claude/settings.json` also fire in bridge turns; skip Claude-only hooks with `[ -n "$PI_CODING_AGENT" ] && exit 0`.

## Customization inventory

| Resource | What it does / why it exists |
|---|---|
| `themes/felix-night.json` | Dark navy panels, cyan/lavender/purple accents, readable diffs and syntax colors; HTML export palette included. |
| OMP theme package + `piOmpTheme` setting | OMP preset: framed editor and model/thinking/Git/context status, auto-applies Felix Night. Uses the package defaults rather than adding core monkey patches. |
| `extensions/flair.mjs` | Cyan/purple animated “Working” text; native Pi indicator owns the 120 ms timer. `/flair [on|off]` toggles it. No extra process or independent timer. |
| `extensions/chat-title.mjs` | Right-aligned session name above the editor, visible even when the OMP editor replaces the footer; refreshes on session start/rename, truncates by terminal columns, sanitizes controls, TUI-only widget. |
| `extensions/chat-namer.mjs` | Titles an unnamed chat after prompt 1 and refines it after prompt 3. Manual `/name` is respected. Uses Claude Haiku 5.5 at medium effort, a 30-second timeout, no tools/MCP/settings/session persistence, at most 60 title characters. Failure leaves the existing name/“Untitled chat”. |
| `extensions/system-prompts.mjs` | Reads `instructions/*.md` once and adds named `systemPromptOptions.sections` for every provider. Explicitly loaded in children; avoids replacing the bridge's captured prompt. |
| `instructions/claude-in-pi-considerations.md` | Agent-visible bridge authentication, native delegation, foreground child prompt capture, supervision, prompt compatibility and cache gotchas. |
| `subagents.json` | Rich inline output; fleet above editor; redundant async widget off; foreground default for applicable single-run calls; fresh child context; eager tool activation; recorded auto authority policy. |
| `settings.json` → `subagents` | Medium child thinking; installer resolves bridge and instruction-loader paths for foreground/background children while leaving ambient UI extensions out. Model normally inherits the parent unless explicitly overridden. |
| `prompts/browser-test.md` | `/browser-test <url and flow>`: named isolated Playwright CLI work, screenshots, console/network checks, 60-second idle timeout, close browser on success/failure. |
| `settings.json` → terminal | Fullscreen UI, compact startup header, inline images where supported, terminal progress hints. |
| Shared skills | `~/.agents/skills`, installed separately by `scripts/install-skills.sh`; same copies used by Pi/OMP and compatibility links for other CLIs. No duplicate Pi skill tree. |

The auto-namer sends excerpts of the first three user prompts (up to 600 characters each) to Claude as an additional subscription query. It runs even when the main model is OpenAI, and can run outside the TUI. This is deliberate installed behavior, not authority to launch coding helpers via shell. Disable automatic naming by switching the package manifest to a display-only widget if that query/privacy trade-off is unsuitable.

**Trusted personal-workstation profile:** `defaultProjectTrust: always` loads project code without prompting. Subagent `authorityPolicy` records `auto` for cleanup/discard, schedule, budget-grant, control and pane actions (runtime guardrails still apply). For unfamiliar repositories or unattended machines, set project trust to `ask` and sensitive authority actions to `confirm`/`forbid` before starting Pi. The installer reapplies the recorded trusted profile. Pi/extension execution is not a sandbox.

## Browser testing (optional CLI)

```bash
npm install -g @playwright/cli
playwright-cli --help
# In Pi: /browser-test http://localhost:3000 test the signup flow
```

The desktop prompt selects installed Google Chrome with `--browser=chrome`; request `--headed` if needed. Browsers only start for browser work and add memory while active. Reuse a project's existing Playwright suite for durable regression tests. The office container instead supplies an image-owned Chromium/cache wrapper and isolated headless launch config; that container-specific wrapper is not a desktop prerequisite.

## Agent visibility and subagent operation

Root `AGENTS.md` routes repository agents here for Pi installation/customization/debugging. The bundled instruction loader supplies the runtime rules to **every Pi provider and explicitly to native children**, even when Pi works outside this repository. Start a **new session** after changing instruction files: the Claude bridge captures the prompt on the first request and reuses it.

Ask for a scout/worker/reviewer or oracle when delegation is wanted. Run `/subagents-doctor`, `/subagents-guide [topic]`, and `/subagents-fleet` for installed-version help and live transcripts. Ctrl+O expands rich inline results; the inspector supports steering and stopping. Open a stopped child's saved session with `pi --session /absolute/path/to/child-session.jsonl`; this is continuation, not takeover of a running session. A separate live terminal requires a supported inspector integration.

For a Claude child `prompt-capture` failure, check `subagents.defaultSubagentOnlyExtensions` contains both installed bridge `src/index.ts` and this bundle's loader. Preserve exact failure/run evidence before any retry. Do not silently switch to shell CLI helpers. Ordinary async completion wakes the launching parent process; a reopened parent must inspect status instead.

Abort, `/compact`, tree navigation, API errors and session reopen can rebuild Claude Code's history and miss prompt caches. Replacing the whole system prompt is incompatible; use sections/appended instructions. Neither theme nor flair adds an idle worker. More concurrent children/browsers consume more RAM; no tiny Node heap limit or hard RSS cap is installed.

## Previous experiment and office provenance

The older `~/dev/pi-setup` was an isolated agent-dir experiment with its own launcher, direct Anthropic Opus default, optional Playwright installed under `tools/`, `flair-check.mjs`, and `memory-check.py`. Its README predates the active bridge/managed install and says packages were not installed; **that is not the current setup**. Never copy its `auth.json`, model store, or sessions. Its 150 MB idle target was a measurement goal, not a cap or production guarantee; the experiment disabled optional OMP UI if it exceeded that target. Active children, browsers, conversation growth and startup peaks were outside that test.

Bundled title/namer/flair/theme source was taken from `RossPlunkett/new-agent-office` at commit `7f3bbeff783677dd01824f035457dde309c93f50`, `deploy/container/pi/`. The desktop display-only title widget lived separately in `~/.pi/agent/extensions/chat-title.ts`; this bundle consolidates it with the office auto-namer so only one widget owns the key. The office instruction loader depended on a sibling `system-prompts/` directory; ours reads bundled `instructions/` instead. Browser prompt comes from the desktop experiment with its launcher-only claim removed. Upstream third-party packages are installed, not vendored.

## Verification and maintenance

```bash
./tests/test-pi.sh                 # isolated config/backup/repeat-run checks; no model requests
node tests/test-pi-extensions.mjs  # uses installed Pi peers; widget/auto-namer/flair/sections checks
./scripts/secret-scan.sh
pi list
```

Interactive acceptance after sign-in: see Felix Night/framed editor and title above it; rename via `/name`; verify `/flair off` and `/flair on`; request a small foreground Claude reviewer and a small async one and confirm visible results in the fleet. Browser acceptance is separate and optional. Offline tests do not prove account authentication, real model availability, live child execution or terminal appearance.

Review package changelogs before changing pins. Installed Pi docs live under its package root `docs/`; extension docs under `~/.pi/agent/npm/node_modules/{pi-subagents,pi-claude-bridge}/`. Keep secrets and diagnostic traces outside Git. Consult [upstream Pi](https://pi.dev), [pi-subagents](https://github.com/nicobailon/pi-subagents), and [pi-claude-bridge](https://www.npmjs.com/package/pi-claude-bridge) for current interfaces; use installed-version docs for this pinned profile.
