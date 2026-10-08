// Capture once per session to keep the bridge's cached system prompt stable.
import { readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const folder = new URL('../instructions/', import.meta.url);

export default function (pi) {
  const prompts = readdirSync(folder).filter(name => name.endsWith('.md')).sort()
    .map(name => [name.slice(0, -3), readFileSync(new URL(name, folder), 'utf8').trim()]);
  const guide = fileURLToPath(new URL('../README.md', import.meta.url));
  pi.on('before_agent_start', event => {
    event.systemPromptOptions.sections['pi-workstation-profile'] = `For Pi installation, restoration, UI customization, subagents, Claude bridge, model authentication, browser testing, or Pi failures: read ${guide} before editing or advising. This is the portable source of truth for the installed workstation profile; credentials and sessions remain per machine.`;
    for (const [name, text] of prompts) event.systemPromptOptions.sections[name] = text;
  });
}
