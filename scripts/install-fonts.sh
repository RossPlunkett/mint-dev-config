#!/usr/bin/env bash
set -euo pipefail

archive="$(mktemp)"
trap 'rm -f "$archive"' EXIT
for font in JetBrainsMono Monofur 3270 HeavyData; do
    font_dir="$HOME/.local/share/fonts/${font}NerdFont"
    mkdir -p "$font_dir"
    curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.zip" -o "$archive"
    unzip -oq "$archive" -d "$font_dir"
done
fc-cache -f "$HOME/.local/share/fonts"
