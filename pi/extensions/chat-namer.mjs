import { spawn } from 'node:child_process';
import os from 'node:os';

// Titles a Pi chat for chat-title.mjs: Claude Haiku 5.5 at medium effort, through the `claude` CLI as
// the office's task namer does (src/server/tasks.ts). Kept apart from the widget so it loads outside Pi.
const TITLE_MAX = 60;
const TIMEOUT_MS = 30_000;
const SYSTEM = 'You title chat sessions with a coding agent. Reply with only a title of 3 to 6 words for what the user wants, in sentence case, with no quotes and no full stop.';
// From a parent Claude Code session: they would make the namer think it's nested.
const SCRUB = ['CLAUDECODE', 'CLAUDE_CODE_ENTRYPOINT', 'CLAUDE_CODE_SSE_PORT', 'CLAUDE_CODE_EXECPATH', 'CLAUDE_PID', 'CLAUDE_EFFORT', 'ANTHROPIC_API_KEY', 'ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_BASE_URL'];

/** Haiku's title for these prompts, or null when it can't give one. */
export function titleFor(prompts, claude = 'claude') {
  const input = `Title this chat. What the user asked, oldest first:\n${prompts.map((p, i) => `${i + 1}. ${p.replace(/\s+/g, ' ').trim().slice(0, 600)}`).join('\n')}`;
  const args = ['-p', '--model', 'claude-haiku-5-5', '--effort', 'medium', '--system-prompt', SYSTEM, '--tools', '', '--setting-sources', '', '--strict-mcp-config', '--disable-slash-commands', '--no-session-persistence'];
  const env = { ...process.env };
  for (const k of SCRUB) delete env[k];
  return new Promise(resolve => {
    let out = '';
    const child = spawn(claude, args, { cwd: os.tmpdir(), env, stdio: ['pipe', 'pipe', 'ignore'] });
    const timer = setTimeout(() => child.kill('SIGKILL'), TIMEOUT_MS);
    child.stdout.setEncoding('utf8');
    child.stdout.on('data', d => (out += d));
    child.on('error', () => resolve(null));
    child.on('close', code => {
      clearTimeout(timer);
      resolve(code === 0 ? cleanTitle(out) : null);
    });
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
