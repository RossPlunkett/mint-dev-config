import { truncateToWidth, visibleWidth } from '@earendil-works/pi-tui';
import { titleFor } from './chat-namer.mjs';

// Keeps the session name visible when the OMP editor replaces Pi's footer, and names an unnamed
// chat itself (chat-namer.mjs) from the first prompt, and once more from the first three. A name set
// with /name is never replaced.

/** Prompts after which the chat is (re)named. */
const NAME_AT = [1, 3];

export default function chatTitle(pi) {
  const showTitle = ctx => {
    if (ctx.mode !== 'tui') return;
    ctx.ui.setWidget('chat-title', () => ({
      render(width) {
        if (width <= 0) return [];
        const name = (ctx.sessionManager.getSessionName() || 'Untitled chat')
          .replace(/[\x00-\x1f\x7f-\x9f\u2028\u2029]/g, ' ');
        const title = truncateToWidth(name, width);
        return [' '.repeat(Math.max(0, width - visibleWidth(title))) + `\x1b[39m${title}`];
      },
      invalidate() {},
    }), { placement: 'aboveEditor' });
  };

  // This session's prompts so far, the name this extension last gave it, and which session it is.
  let prompts = [];
  let named;
  let epoch = 0;
  pi.on('session_start', (_event, ctx) => {
    prompts = [];
    named = undefined;
    epoch++;
    showTitle(ctx);
  });
  pi.on('session_info_changed', (_event, ctx) => showTitle(ctx));
  pi.on('before_agent_start', (event, ctx) => {
    const prompt = event.prompt?.trim();
    if (!prompt || prompt.startsWith('/')) return;
    prompts.push(prompt);
    if (!NAME_AT.includes(prompts.length)) return;
    // Named by hand (or before this run): leave it.
    const current = ctx.sessionManager.getSessionName();
    if (current && current !== named) return;
    const at = epoch;
    titleFor(prompts.slice()).then(title => {
      if (!title || at !== epoch) return;
      const now = ctx.sessionManager.getSessionName();
      if (now && now !== named) return;
      named = title;
      pi.setSessionName(title);
    });
  });
}
