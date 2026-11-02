import { spawn } from 'node:child_process';
import os from 'node:os';

// Titles a Pi chat for chat-title.mjs, through the `claude` CLI or `pi`. Kept apart from the widget so it
// loads outside Pi. Naming has its own primary and fallback, independent of the session's model.
export const DEFAULT_NAMING = { primary: { model: 'claude-bridge/claude-haiku-5-5', effort: 'medium' }, fallback: { model: 'openai-codex/gpt-6-luna', effort: 'medium' } };
const TITLE_MAX = 60;
const TIMEOUT_MS = 30_000;
const SYSTEM = 'You title chat sessions with a coding agent. Reply with only a title of 3 to 6 words for what the user wants, in sentence case, with no quotes and no full stop.';
// From a parent Claude Code session: they would make the namer think it's nested.
const SCRUB = ['CLAUDECODE', 'CLAUDE_CODE_ENTRYPOINT', 'CLAUDE_CODE_SSE_PORT', 'CLAUDE_CODE_EXECPATH', 'CLAUDE_PID', 'CLAUDE_EFFORT', 'ANTHROPIC_API_KEY', 'ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_BASE_URL'];

/** A title for these prompts, or null when neither model gives one. options: { claude?, pi?, naming? }. */
export async function titleFor(prompts, options = {}) {
  const input = `Title this chat. What the user asked, oldest first:\n${prompts.map((p, i) => `${i + 1}. ${p.replace(/\s+/g, ' ').trim().slice(0, 600)}`).join('\n')}`;
  const naming = options.naming ?? DEFAULT_NAMING;
  for (const choice of [naming.primary, naming.fallback].filter(Boolean)) {
    const text = await runTitleModel(choice, input, options);
    const title = text === null ? null : cleanTitle(text);
    if (title) return title;
  }
  return null;
}

function runTitleModel(choice, input, options) {
  const bridge = choice.model.startsWith('claude-bridge/');
  const command = bridge ? options.claude ?? 'claude' : options.pi ?? 'pi';
  const args = bridge
    ? ['-p', '--model', choice.model.slice('claude-bridge/'.length), '--effort', choice.effort, '--system-prompt', SYSTEM, '--tools', '', '--setting-sources', '', '--strict-mcp-config', '--disable-slash-commands', '--no-session-persistence']
    : ['-p', '--model', choice.model, '--thinking', choice.effort, '--no-session', '--no-tools', '--no-extensions', '--no-skills', '--no-prompt-templates', '--no-context-files', '--no-mcp', '--system-prompt', SYSTEM];
  const env = { ...process.env };
  for (const k of SCRUB) delete env[k];
  return new Promise(resolve => {
    let out = '';
    const child = spawn(command, args, { cwd: os.tmpdir(), env, stdio: ['pipe', 'pipe', 'ignore'] });
    let ended = false;
    const finish = value => { if (ended) return; ended = true; clearTimeout(timer); resolve(value); };
    const timer = setTimeout(() => { child.kill('SIGKILL'); finish(null); }, TIMEOUT_MS);
    child.stdout.setEncoding('utf8');
    child.stdout.on('data', d => { out += d; if (out.length > 16_000) { child.kill('SIGKILL'); finish(null); } });
    child.on('error', () => finish(null));
    child.on('close', code => finish(code === 0 ? out : null));
    child.stdin.on('error', () => {});
    child.stdin.end(input);
  });
}

/** The model's reply as a one-line title, or null. */
export function cleanTitle(out) {
  const line = out.trim().split('\n')[0].replace(/^(title:\s*)/i, '').replace(/^["'*\s]+|["'*.\s]+$/g, '');
  if (!line) return null;
  return line.length > TITLE_MAX ? `${line.slice(0, TITLE_MAX - 1).trimEnd()}…` : line;
}
