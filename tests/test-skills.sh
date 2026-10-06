#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail() { printf 'not ok - %s\n' "$1" >&2; exit 1; }
pass() { printf 'ok - %s\n' "$1"; }
fixture="$work/config"
remote="$work/upstream"
mkdir -p "$fixture/scripts" "$fixture/manifests" "$fixture/fallback-skills/example/demo" "$remote/skills/demo" "$work/home"
cp "$ROOT/scripts/install-skills.sh" "$fixture/scripts/install-skills.sh"
printf '%s\n' '---' 'name: demo' 'description: Upstream fixture.' '---' 'Upstream instructions.' >"$remote/skills/demo/SKILL.md"
printf 'upstream reference\n' >"$remote/skills/demo/reference.txt"
printf '%s\n' '---' 'name: demo' 'description: Fallback fixture.' '---' 'Bundled fallback instructions.' >"$fixture/fallback-skills/example/demo/SKILL.md"
printf 'bundled reference\n' >"$fixture/fallback-skills/example/demo/reference.txt"
git -C "$remote" init --quiet
git -C "$remote" add .
git -C "$remote" -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m fixture
printf 'example\t%s\tskills/demo\tdemo\n' "$remote" >"$fixture/manifests/skills.tsv"
HOME="$work/home" bash "$fixture/scripts/install-skills.sh" >/dev/null
cmp "$remote/skills/demo/SKILL.md" "$work/home/.agents/skills/demo/SKILL.md" || fail 'upstream skill not preferred'
cmp "$remote/skills/demo/reference.txt" "$work/home/.agents/skills/demo/reference.txt" || fail 'upstream resource missing'
for dir in .claude/skills .codex/skills .config/opencode/skills; do
    cmp "$remote/skills/demo/SKILL.md" "$work/home/$dir/demo/SKILL.md" || fail "skill unavailable in $dir"
done
[[ ! -e "$work/home/.pi/agent/skills" && ! -e "$work/home/.omp/agent/skills" ]] || fail 'duplicate native skill locations created'
pass 'online installation prefers upstream and preserves skill resources across agent surfaces'

# Download failure must select the complete bundled copy, including resources.
printf 'example\t%s\tskills/demo\tdemo\n' "$work/missing-upstream" >"$fixture/manifests/skills.tsv"
HOME="$work/home" bash "$fixture/scripts/install-skills.sh" >/dev/null 2>&1
cmp "$fixture/fallback-skills/example/demo/SKILL.md" "$work/home/.agents/skills/demo/SKILL.md" || fail 'offline fallback unavailable'
cmp "$fixture/fallback-skills/example/demo/reference.txt" "$work/home/.agents/skills/demo/reference.txt" || fail 'offline fallback resource missing'
pass 'failed upstream download installs complete bundled fallback'

# A successful checkout that no longer contains the skill also needs fallback.
printf 'example\t%s\tskills/removed\tdemo\n' "$remote" >"$fixture/manifests/skills.tsv"
HOME="$work/home" bash "$fixture/scripts/install-skills.sh" >/dev/null 2>&1
cmp "$fixture/fallback-skills/example/demo/SKILL.md" "$work/home/.agents/skills/demo/SKILL.md" || fail 'missing upstream skill fallback unavailable'
pass 'missing upstream skill uses bundled fallback'

mkdir -p "$work/protected/.agents/skills/demo"
printf 'local custom instructions\n' >"$work/protected/.agents/skills/demo/SKILL.md"
HOME="$work/protected" bash "$fixture/scripts/install-skills.sh" >/dev/null 2>&1
[[ "$(cat "$work/protected/.agents/skills/demo/SKILL.md")" == 'local custom instructions' ]] || fail 'custom skill overwritten'
pass 'existing custom skill is preserved'

# Migrate the previous backing store and native aliases without leaving duplicates.
legacy="$work/legacy"
old_store="$legacy/.local/share/mint-dev-config-skills"
mkdir -p "$old_store/demo" "$legacy/.agents/skills" "$legacy/.pi/agent/skills" "$legacy/.omp/agent/skills" "$legacy/.claude/skills"
cp "$remote/skills/demo/SKILL.md" "$old_store/demo/SKILL.md"
for dir in .agents/skills .pi/agent/skills .omp/agent/skills .claude/skills; do
    ln -s "$old_store/demo" "$legacy/$dir/demo"
done
HOME="$legacy" bash "$fixture/scripts/install-skills.sh" >/dev/null 2>&1
[[ -d "$legacy/.agents/skills/demo" && ! -L "$legacy/.agents/skills/demo" ]] || fail 'shared skill not materialized'
[[ ! -e "$legacy/.pi/agent/skills" && ! -e "$legacy/.omp/agent/skills" && ! -e "$old_store" ]] || fail 'legacy duplicate skills remain'
cmp "$fixture/fallback-skills/example/demo/SKILL.md" "$legacy/.claude/skills/demo/SKILL.md" || fail 'compatibility link not migrated'
pass 'legacy skill aliases migrate to one shared copy without native duplicates'
