import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { homedir } from 'node:os';
import { refreshUsage } from './usage-refresh.mjs';

const percent = value => typeof value === 'number' && Number.isFinite(value) && value >= 0
  ? `${value}% used` : 'unknown';

function freshness(timestamp, now) {
  if (!Number.isFinite(timestamp) || timestamp <= 0 || timestamp > now) return 'age unknown';
  const seconds = Math.floor((now - timestamp) / 1000);
  return `${seconds}s old${seconds >= 60 ? ' — stale' : ''}`;
}

/** Read only the plugin's cache: no credentials, network requests or inference. */
export async function readUsage(agentDir, now = Date.now()) {
  const file = path.join(agentDir, 'cache/pi-usage-limits.json');
  let state;
  try {
    state = JSON.parse(await readFile(file, 'utf8'));
    if (!state || typeof state !== 'object' || Array.isArray(state)) throw new Error('Expected an object');
  } catch (error) {
    if (error.code === 'ENOENT') return 'No usage cache yet. Run /usage to fetch subscription limits without inference.';
    throw new Error(`Cannot read usage cache (${file}): ${error.message}`);
  }
  const claude = state.anthropic_last_limits;
  const codex = state.codex_last_limits;
  const lines = ['Subscription usage (cached; no inference)'];
  lines.push(claude
    ? `Claude: 5h ${percent(claude.rate_limits?.five_hour?.utilization)}, 7d ${percent(claude.rate_limits?.seven_day?.utilization)} (${freshness(state.anthropic_last_api_call, now)})`
    : 'Claude: no cached data');
  if (codex) {
    const windows = [codex.primary, codex.secondary].filter(Boolean).map(window => {
      const minutes = window.windowDurationMins;
      const label = typeof minutes === 'number' && minutes > 0 ? `${minutes / 60}h` : 'window';
      return `${label} ${percent(window.usedPercent)}`;
    });
    lines.push(`Codex: ${windows.join(', ') || 'usage unavailable'} (${freshness(state.codex_last_api_call, now)})`);
  } else lines.push('Codex: no cached data');
  lines.push('Codex subscription only, not OpenAI API limits. Cache may belong to a previous login.');
  return lines.join('\n');
}

export default function (pi) {
  const command = {
    description: 'Fetch Claude/Codex limits without inference; use "cached" to skip network requests',
    handler: async (args, ctx) => {
      try {
        const configured = process.env.PI_CODING_AGENT_DIR || path.join(homedir(), '.pi/agent');
        const agentDir = configured === '~' ? homedir()
          : configured.startsWith('~/') ? path.join(homedir(), configured.slice(2)) : configured;
        if (args.trim() && args.trim() !== 'cached' && args.trim() !== 'refresh') {
          ctx.ui.notify('Usage: /usage [cached|refresh] (or /usag)', 'error');
          return;
        }
        const errors = args.trim() === 'cached' ? [] : await refreshUsage(agentDir, ctx.modelRegistry);
        ctx.ui.notify([await readUsage(agentDir), ...errors].join('\n'), errors.length ? 'warning' : 'info');
      } catch (error) {
        ctx.ui.notify(error.message, 'error');
      }
    },
  };
  pi.registerCommand('usag', command);
  pi.registerCommand('usage', command);
}
