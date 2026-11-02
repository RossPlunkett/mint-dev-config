import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import { mkdir, readFile, writeFile, rename } from 'node:fs/promises';
import path from 'node:path';

const require = createRequire(import.meta.url);

export async function queryClaude(agentDir) {
  const sdkPath = require.resolve('@anthropic-ai/claude-agent-sdk', {
    paths: [path.join(agentDir, 'npm')],
  });
  const { query } = await import(pathToFileURL(sdkPath).href);
  const abortController = new AbortController();
  const timer = setTimeout(() => abortController.abort(), 20_000);
  let q;
  try {
    q = query({
      // Keep the SDK control channel open without submitting an inference prompt.
      prompt: (async function* () { await new Promise(() => {}); })(),
      options: {
        abortController, persistSession: false, settingSources: [], strictMcpConfig: true,
        env: { ...process.env, CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: undefined },
      },
    });
    const result = await q.usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET({ skipBehaviors: true });
    if (!result?.rate_limits) throw new Error('Claude Code returned no subscription limits; check its login.');
    return { subscription: result.subscription_type, available: result.rate_limits_available, rate_limits: result.rate_limits };
  } finally {
    clearTimeout(timer);
    q?.close();
  }
}

export async function queryCodex(registry) {
  const token = await registry.getApiKeyForProvider('openai-codex');
  if (!token) throw new Error('No Pi openai-codex login. The openai login is separate and its limits are not available here.');
  const account = JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString())['https://api.openai.com/auth']?.chatgpt_account_id;
  if (!account) throw new Error('Codex login has no ChatGPT account ID.');
  const response = await fetch('https://chatgpt.com/backend-api/wham/usage', {
    headers: { Authorization: `Bearer ${token}`, 'ChatGPT-Account-Id': account },
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) throw new Error(`Codex usage request failed: HTTP ${response.status}`);
  const body = await response.json();
  const window = w => w ? { usedPercent: w.used_percent, windowDurationMins: w.limit_window_seconds ? w.limit_window_seconds / 60 : null, resetsAt: w.reset_at ?? null } : null;
  return { primary: window(body.rate_limit?.primary_window), secondary: window(body.rate_limit?.secondary_window) };
}

/** Independent of the selected model; requests usage metadata only, never inference. */
export async function refreshUsage(agentDir, registry, queries = { claude: queryClaude, codex: queryCodex }) {
  const updates = {};
  const errors = [];
  for (const [name, prefix] of [['claude', 'anthropic'], ['codex', 'codex']]) {
    try {
      updates[`${prefix}_last_limits`] = await queries[name](name === 'claude' ? agentDir : registry);
      updates[`${prefix}_last_api_call`] = Date.now();
    } catch (error) {
      errors.push(`${name}: ${error.message}`);
    }
  }
  if (Object.keys(updates).length) {
    const file = path.join(agentDir, 'cache/pi-usage-limits.json');
    let existing = {};
    try {
      existing = JSON.parse(await readFile(file, 'utf8'));
      if (!existing || typeof existing !== 'object' || Array.isArray(existing)) throw new Error('Usage cache must be an object');
    } catch (error) { if (error.code !== 'ENOENT') throw error; }
    await mkdir(path.dirname(file), { recursive: true });
    const temporary = `${file}.${process.pid}.${Date.now()}.tmp`;
    await writeFile(temporary, JSON.stringify({ ...existing, ...updates }, null, 2), { mode: 0o600 });
    await rename(temporary, file);
  }
  return errors;
}
