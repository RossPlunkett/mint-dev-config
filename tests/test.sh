#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail() { printf 'not ok - %s\n' "$1" >&2; exit 1; }
pass() { printf 'ok - %s\n' "$1"; }

# A preview must not create user configuration or invoke installation phases.
mkdir -p "$work/preview"
HOME="$work/preview" "$ROOT/bootstrap.sh" --dry-run --with-projects --skip-build >/dev/null
[[ -z "$(find "$work/preview" -mindepth 1 -print -quit)" ]] || fail 'preview modifies home'
pass 'bootstrap preview leaves home untouched'

home="$work/home"
mkdir -p "$home/.config/i3" "$home/.local/bin" "$home/.t3/userdata"
printf 'original shell configuration\n' >"$home/.bashrc"
printf 'independently managed karaoke launcher\n' >"$home/.local/bin/karaoke-workflow"
ln -s "$ROOT/dotfiles/i3/ROFWorkflow.sh" "$home/.config/i3/ROFWorkflow.sh"
ln -s "$ROOT/dotfiles/t3/keybindings.json" "$home/.t3/userdata/keybindings.json"
ln -s "$ROOT/dotfiles/i3/monitor-layout.sh" "$home/.config/i3/monitor-layout.sh"
HOME="$home" "$ROOT/install-config.sh" --no-dconf >/dev/null
backup="$(find "$home/.config-backups" -name .bashrc -print -quit)"
[[ -n "$backup" ]] && [[ "$(cat "$backup")" == 'original shell configuration' ]] || fail 'original shell configuration lost'
[[ "$(readlink -f "$home/.bashrc")" == "$ROOT/dotfiles/bashrc" ]] || fail 'shell config not applied'
[[ ! -L "$home/.config/i3/ROFWorkflow.sh" && ! -L "$home/.config/i3/monitor-layout.sh" && ! -L "$home/.t3/userdata/keybindings.json" ]] || fail 'retired managed links remain'
[[ "$(cat "$home/.local/bin/karaoke-workflow")" == 'independently managed karaoke launcher' ]] || fail 'unmanaged launcher changed'
pass 'configuration replacement preserves originals and retires only owned links'

[[ "$(readlink -f "$home/.config/mcp/mcp.json")" == "$ROOT/dotfiles/mcp/mcp.json" ]] || fail 'Blender MCP config not linked'
[[ "$(readlink -f "$home/.local/bin/playwright-cli")" == "$ROOT/dotfiles/local-bin/playwright-cli" ]] || fail 'playwright-cli not linked'
cmp "$ROOT/dotfiles/omp/config.yml" "$home/.omp/agent/config.yml" || fail 'OMP config not copied'
grep -qx "Exec=$home/.local/bin/chrome-clean-link %U" "$home/.local/share/applications/chrome-clean-link.desktop" || fail 'link launcher path not set'
if command -v xdg-mime >/dev/null 2>&1; then
    grep -q 'x-scheme-handler/https=chrome-clean-link.desktop' "$home/.config/mimeapps.list" || fail 'link handler not set as default'
fi
printf 'my omp settings\n' >"$home/.omp/agent/config.yml"
HOME="$home" "$ROOT/install-config.sh" --no-dconf >/dev/null
[[ "$(cat "$home/.omp/agent/config.yml")" == 'my omp settings' ]] || fail 'existing OMP config replaced'
pass 'new links, link handler and OMP config apply without replacing OMP settings'

# The always-on script must reach all three layers, and undo them, without touching this machine.
stubs="$work/stubs" calls="$work/always-on-calls"
mkdir -p "$stubs" "$work/always-on"
for tool in systemctl gsettings sudo; do
    printf '#!/usr/bin/env bash\nprintf "%s %%s\\n" "$*" >>"%s"\n[[ "$*" == list-schemas ]] && printf "org.cinnamon.settings-daemon.plugins.power\\n"\nexit 0\n' "$tool" "$calls" >"$stubs/$tool"
    chmod +x "$stubs/$tool"
done
HOME="$work/always-on" PATH="$stubs:$PATH" "$ROOT/scripts/install-always-on.sh" >/dev/null
cmp "$ROOT/dotfiles/systemd/keep-awake.service" "$work/always-on/.config/systemd/user/keep-awake.service" || fail 'keep-awake unit not installed'
grep -q 'enable --now keep-awake.service' "$calls" || fail 'keep-awake not enabled'
grep -q 'logind.conf.d/50-always-on.conf' "$calls" || fail 'lid setting not installed'
grep -q 'sleep-inactive-battery-type nothing' "$calls" || fail 'Cinnamon sleep not disabled'
HOME="$work/always-on" PATH="$stubs:$PATH" "$ROOT/scripts/install-always-on.sh" --disable >/dev/null
[[ ! -e "$work/always-on/.config/systemd/user/keep-awake.service" ]] || fail 'keep-awake unit not removed'
grep -q 'reset org.cinnamon.settings-daemon.plugins.power sleep-inactive-ac-type' "$calls" || fail 'Cinnamon sleep not restored'
pass 'always-on script applies and undoes all three layers'

before="$(find "$home/.config-backups" -type f -o -type l | sort)"
HOME="$home" "$ROOT/install-config.sh" --no-dconf >/dev/null
after="$(find "$home/.config-backups" -type f -o -type l | sort)"
[[ "$before" == "$after" ]] || fail 'repeat application makes new backups'
pass 'repeat configuration application is idempotent'

# Interactive shells must retain the caller-selected project directory.
mkdir -p "$home/dev/csoundfreak" "$work/project"
(cd "$work/project" && HOME="$home" PWD_REPORT="$work/pwd" bash --noprofile --rcfile "$ROOT/dotfiles/bashrc" -ic 'pwd > "$PWD_REPORT"' >/dev/null 2>&1)
[[ "$(cat "$work/pwd")" == "$work/project" ]] || fail 'interactive shell changes project directory'
pass 'interactive shell preserves project directory'

if command -v i3 >/dev/null 2>&1; then
    parser_output="$(i3 -C -c "$ROOT/dotfiles/i3/config" 2>&1)" || fail 'i3 configuration rejected'
    [[ "$parser_output" != *'ERROR: CONFIG:'* ]] || fail 'i3 configuration rejected'
    pass 'i3 accepts configuration'
fi
bash "$ROOT/tests/test-skills.sh"
printf 'All workstation behavior checks passed.\n'
