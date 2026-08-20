#!/usr/bin/env bash
set -euo pipefail

checkout="$HOME/.local/share/mattpocock-skills"
if [[ ! -d "$checkout/.git" ]]; then
    git clone https://github.com/mattpocock/skills.git "$checkout"
else
    git -C "$checkout" pull --ff-only
fi

mapfile -t skill_paths < <(python3 - "$checkout/.claude-plugin/plugin.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as manifest:
    for path in json.load(manifest)["skills"]:
        print(path.removeprefix("./"))
PY
)

for destination in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.agents/skills"; do
    mkdir -p "$destination"
    for relative in "${skill_paths[@]}"; do
        source_path="$checkout/$relative"
        name="$(basename "$relative")"
        target="$destination/$name"
        if [[ -e "$target" && ! -L "$target" ]]; then
            printf 'skip    existing skill %s\n' "$target"
            continue
        fi
        ln -sfn "$source_path" "$target"
    done
done

