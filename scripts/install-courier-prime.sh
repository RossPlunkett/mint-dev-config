#!/usr/bin/env bash
set -euo pipefail

# Courier Prime static TTFs from the official quoteunquoteapps/CourierPrime
# source repository, pinned to a commit and verified by SHA-256.
commit=7fd585a2dd4c1612c79b3308e300923d1c13df93
base_url="https://raw.githubusercontent.com/quoteunquoteapps/CourierPrime/$commit"
font_dir="$HOME/.local/share/fonts/CourierPrime"

files=(
    "72f793376f8e2841656bf21d77a5de010f2929bd6956a22ee848ad0c7eb978af  fonts/ttf/CourierPrime-Regular.ttf"
    "f1b9a5829789f7e56432a9f3bc7665ef4531dbba1c112639e48bef39621a006b  fonts/ttf/CourierPrime-Italic.ttf"
    "ff1f38786c849d1c41fa8e447960abdb2bd75fdfb0cfcdeb524fad65a5af3638  fonts/ttf/CourierPrime-Bold.ttf"
    "3355273f3ea6d6362658f9564f4e83d59e156cf1a182e3c1592b5c5943627dcc  fonts/ttf/CourierPrime-BoldItalic.ttf"
    "9a755af092b494944c99f471be6fddd19b006a448fefdc4717e4ee0aa09a97b0  OFL.txt"
)

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$font_dir"

for entry in "${files[@]}"; do
    hash="${entry%%  *}"
    path="${entry#*  }"
    name="$(basename "$path")"
    curl -fsSL --proto '=https' "$base_url/$path" -o "$work_dir/$name"
    printf '%s  %s\n' "$hash" "$name" | (cd "$work_dir" && sha256sum --check --strict --quiet -)
    install -m 0644 "$work_dir/$name" "$font_dir/$name"
done

fc-cache -f "$font_dir"
