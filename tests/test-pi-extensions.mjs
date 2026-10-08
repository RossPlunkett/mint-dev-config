import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { readFileSync, existsSync, mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import os from 'node:os';

const agent = process.env.PI_CODING_AGENT_DIR || path.join(os.homedir(), '.pi/agent');
let root = process.env.PI_TEST_PACKAGE_ROOT;
if (!root) {
  const current = path.join(agent, 'install/current-version');
  root = existsSync(current)
    ? path.join(agent, 'install/releases', readFileSync(current, 'utf8').trim(), 'node_modules/@earendil-works/pi-coding-agent')
    : path.join(execFileSync('npm', ['root', '-g'], { encoding: 'utf8' }).trim(), '@earendil-works/pi-coding-agent');
}
const require = createRequire(path.join(root, 'package.json'));
const { createJiti } = require('jiti');
const tuiPath = require.resolve('@earendil-works/pi-tui');
const jiti = createJiti(import.meta.url, { alias: { '@earendil-works/pi-tui': tuiPath } });
const { visibleWidth } = await jiti.import(tuiPath);
const { default: chatTitle } = await jiti.import(new URL('../pi/extensions/chat-title.mjs', import.meta.url).pathname);
const { cleanTitle, titleFor } = await import('../pi/extensions/chat-namer.mjs');
const { default: flair } = await import('../pi/extensions/flair.mjs');
const { default: instructions } = await import('../pi/extensions/system-prompts.mjs');

const handlers = {};
chatTitle({ on: (event, fn) => { handlers[event] = fn; }, setSessionName: () => assert.fail('manual naming must not launch auto-namer') });
let name;
let widget;
let installs = 0;
const ctx = { mode: 'tui', sessionManager: { getSessionName: () => name }, ui: { setWidget(key, factory, options) {
  assert.equal(key, 'chat-title');
  assert.equal(options.placement, 'aboveEditor');
  widget = factory();
  installs++;
} } };
const plain = line => line.replace(/\x1b\[[0-9;]*m/g, '');
handlers.session_start({}, ctx);
assert.equal(plain(widget.render(20)[0]), '       Untitled chat');
name = 'Manual name';
handlers.session_info_changed({}, ctx);
assert.equal(plain(widget.render(20)[0]), '         Manual name');
// A manual name avoids even invoking the CLI title query, including refinement.
for (let i = 0; i < 3; i++) handlers.before_agent_start({ prompt: 'Keep my manual name' }, ctx);
for (name of ['A very long chat title', '聊天 🐈 café', 'Bad\nname\x1b[31m']) {
  for (const width of [1, 2, 8, 20, 100]) {
    const line = widget.render(width)[0];
    assert.equal(visibleWidth(line), width);
    assert.ok(!/[\n\r\x1b]/.test(plain(line)));
  }
}
assert.deepEqual(widget.render(0), []);
const before = installs;
handlers.session_start({}, { ...ctx, mode: 'rpc' });
assert.equal(installs, before);
assert.equal(cleanTitle('Title: "Set up Pi."\nextra'), 'Set up Pi');
assert.equal(cleanTitle(''), null);
assert.equal(cleanTitle('a'.repeat(100)).length, 60);
const temp = mkdtempSync(path.join(os.tmpdir(), 'pi-namer-test-'));
try {
  const fake = path.join(temp, 'claude');
  writeFileSync(fake, `#!/usr/bin/env node
const assert = require('node:assert/strict');
const args = process.argv.slice(2);
for (const key of ['--tools', '--setting-sources']) assert.equal(args[args.indexOf(key) + 1], '');
assert.ok(args.includes('--strict-mcp-config') && args.includes('--no-session-persistence'));
for (const key of ['ANTHROPIC_API_KEY', 'ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_BASE_URL', 'CLAUDECODE']) assert.equal(process.env[key], undefined);
process.stdin.resume();
process.stdin.on('end', () => console.log('Install Pi profile'));
`, { mode: 0o700 });
  assert.equal(await titleFor(['Set up Pi'], fake), 'Install Pi profile');
  assert.equal(await titleFor(['Set up Pi'], path.join(temp, 'missing')), null);
} finally {
  rmSync(temp, { recursive: true, force: true });
}

const events = {};
let command;
flair({ on: (event, fn) => { events[event] = fn; }, registerCommand(name, spec) { assert.equal(name, 'flair'); command = spec; } });
let indicator;
const ui = { setWorkingMessage() {}, setWorkingIndicator(value) { indicator = value; }, notify() {} };
events.session_start({}, { ui });
assert.equal(indicator.intervalMs, 120);
assert.equal(indicator.frames.length, 10);
await command.handler('off', { ui });
assert.equal(indicator, undefined);
await command.handler('on', { ui });
assert.equal(indicator.frames.length, 10);

let inject;
instructions({ on(event, fn) { assert.equal(event, 'before_agent_start'); inject = fn; } });
const event = { systemPromptOptions: { sections: { existing: 'preserved' } } };
inject(event);
assert.equal(event.systemPromptOptions.sections.existing, 'preserved');
assert.match(event.systemPromptOptions.sections['claude-in-pi-considerations'], /subagent/);
assert.match(event.systemPromptOptions.sections['pi-workstation-profile'], /pi\/README\.md/);
assert.equal(event.systemPrompt, undefined);
console.log('PASS: title alignment/rename/Unicode/control sanitization/modes/manual-name guard/title cleaning, flair, structured instructions (no model calls)');
