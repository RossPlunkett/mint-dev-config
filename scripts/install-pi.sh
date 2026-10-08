#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
if (($#)); then
    printf 'Usage: %s (installs the recorded Pi profile; see pi/README.md)\n' "$0" >&2
    exit 2
fi
if ! command -v pi >/dev/null 2>&1; then
    npm install --global --ignore-scripts @earendil-works/pi-coding-agent@1.1.0
fi
python3 - "$(pi --version)" <<'PY'
import sys
version = tuple(int(n) for n in sys.argv[1].strip().split('.')[:3])
if version < (1, 1, 0):
    raise SystemExit('Pi 1.1.0+ required. Update Pi using its original install method first.')
PY

# Merge preferences, preserving unrelated settings and never opening authentication files.
python3 - "$ROOT" <<'PY'
import json
import os
from pathlib import Path
import shutil
import tempfile

root = Path(__import__('sys').argv[1])
agent = Path(os.environ.get('PI_CODING_AGENT_DIR', Path.home() / '.pi/agent')).expanduser().resolve()
agent.mkdir(parents=True, exist_ok=True)
backup = None

def save(path, value):
    global backup
    text = json.dumps(value, indent=2) + '\n'
    if path.exists() and path.read_text() == text:
        return
    if path.exists():
        if backup is None:
            base = Path.home() / '.config-backups'
            base.mkdir(parents=True, exist_ok=True)
            backup = Path(tempfile.mkdtemp(prefix='pi-', dir=base))
        target = backup / path.relative_to(agent)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)

def load(path):
    return json.loads(path.read_text()) if path.exists() else {}

def merge(old, new):
    for key, value in new.items():
        if isinstance(value, dict) and isinstance(old.get(key), dict):
            merge(old[key], value)
        else:
            old[key] = value
    return old

settings_path = agent / 'settings.json'
settings = merge(load(settings_path), load(root / 'pi/settings.json'))
# Retire the known office package only; keep all unrelated user packages.
packages = settings.setdefault('packages', [])
packages[:] = [entry for entry in packages if not str(entry if isinstance(entry, str) else entry.get('source', '')).endswith('/new-agent-office/deploy/container/pi')]
children = settings.setdefault('subagents', {}).setdefault('defaultSubagentOnlyExtensions', [])
children[:] = [entry for entry in children if entry != str(root / 'pi/extensions/system-prompts.mjs') and not entry.endswith('/new-agent-office/deploy/container/pi/system-prompts.mjs') and not entry.endswith('/pi-claude-bridge/src/index.ts')]
children.extend([str(agent / 'npm/node_modules/pi-claude-bridge/src/index.ts'), str(root / 'pi/extensions/system-prompts.mjs')])
save(settings_path, settings)
for source, target in [('subagents.json', 'extensions/subagent/config.json'), ('claude-bridge.json', 'claude-bridge.json')]:
    path = agent / target
    save(path, merge(load(path), load(root / 'pi' / source)))
# The previously standalone display-only widget duplicates the bundled auto-namer.
widget = agent / 'extensions/chat-title.ts'
if widget.exists():
    if 'export default function chatTitle' in widget.read_text() and 'setWidget("chat-title"' in widget.read_text():
        if backup is None:
            base = Path.home() / '.config-backups'
            base.mkdir(parents=True, exist_ok=True)
            backup = Path(tempfile.mkdtemp(prefix='pi-', dir=base))
        target = backup / 'extensions/chat-title.ts'
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(widget), target)
    else:
        raise SystemExit('Unrecognized extensions/chat-title.ts: review the widget collision manually.')
if backup:
    print(f'Previous Pi configuration backed up to {backup}')
PY

pi install npm:pi-claude-bridge@0.9.2
pi install npm:pi-subagents@0.76.1
pi install npm:@nguyenquangthai/pi-omp-theme@1.0.15
pi install "$ROOT/pi"
printf '\nPi profile installed. Keep this checkout in place; start a NEW session.\n'
printf 'Authenticate Claude Code separately; use Pi /login for OpenAI. See %s/pi/README.md.\n' "$ROOT"
