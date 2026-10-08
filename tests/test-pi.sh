#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/home/.pi/agent/extensions"
cat >"$work/bin/pi" <<'SH'
#!/usr/bin/env bash
if [[ "$1" == --version ]]; then printf '1.1.0\n'; else printf '%s\n' "$*" >>"$HOME/pi-calls"; fi
SH
chmod +x "$work/bin/pi"
export HOME="$work/home" PATH="$work/bin:$PATH"
unset PI_CODING_AGENT_DIR
printf '{"credential":"test-only-sentinel"}\n' >"$HOME/.pi/agent/auth.json"
printf '{"custom":42,"terminal":{"custom":true},"packages":["npm:unrelated","/old/dev/new-agent-office/deploy/container/pi"],"subagents":{"defaultSubagentOnlyExtensions":["/old/.pi/agent/npm/node_modules/pi-claude-bridge/src/index.ts","/old/dev/new-agent-office/deploy/container/pi/system-prompts.mjs","/custom/child.ts"]}}\n' >"$HOME/.pi/agent/settings.json"
printf 'export default function chatTitle() { setWidget("chat-title"); }\n' >"$HOME/.pi/agent/extensions/chat-title.ts"
"$ROOT/scripts/install-pi.sh" >/dev/null
python3 - "$ROOT" <<'PY'
import json
from pathlib import Path
import sys
home = Path.home()
agent = home / '.pi/agent'
s = json.loads((agent / 'settings.json').read_text())
assert s['custom'] == 42 and s['terminal']['custom'] is True
assert s['packages'] == ['npm:unrelated']
assert s['theme'] == 'felix-night' and s['defaultProjectTrust'] == 'always'
assert s['subagents']['defaultSubagentOnlyExtensions'] == ['/custom/child.ts', str(agent / 'npm/node_modules/pi-claude-bridge/src/index.ts'), str(Path(sys.argv[1]) / 'pi/extensions/system-prompts.mjs')]
assert not (agent / 'extensions/chat-title.ts').exists()
assert list((home / '.config-backups').glob('pi-*/extensions/chat-title.ts'))
original = list((home / '.config-backups').glob('pi-*/settings.json'))
assert len(original) == 1 and json.loads(original[0].read_text())['custom'] == 42
assert json.loads((agent / 'extensions/subagent/config.json').read_text())['toolActivation'] == 'eager'
assert json.loads((agent / 'claude-bridge.json').read_text())['askClaude']['enabled'] is False
assert (agent / 'auth.json').read_text() == '{"credential":"test-only-sentinel"}\n'
calls = (home / 'pi-calls').read_text().splitlines()
assert calls == ['install npm:pi-claude-bridge@0.9.2', 'install npm:pi-subagents@0.76.1', 'install npm:@nguyenquangthai/pi-omp-theme@1.0.15', f'install {sys.argv[1]}/pi']
PY
before="$(find "$HOME/.config-backups" -type f | sort)"
"$ROOT/scripts/install-pi.sh" >/dev/null
[[ "$before" == "$(find "$HOME/.config-backups" -type f | sort)" ]]
PI_CODING_AGENT_DIR="$HOME/custom-agent" "$ROOT/scripts/install-pi.sh" >/dev/null
[[ -f "$HOME/custom-agent/settings.json" && ! -f "$HOME/custom-agent/auth.json" ]]
printf 'PASS: Pi merge, backup, widget migration, pins, repeat-run, auth preservation, alternate agent dir\n'
