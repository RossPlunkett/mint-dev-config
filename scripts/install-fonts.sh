#!/usr/bin/env bash
set -euo pipefail

archive="$(mktemp)"
font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
mkdir -p "$font_dir"
curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o "$archive"
unzip -oq "$archive" -d "$font_dir"
fc-cache -f "$font_dir"
rm -f "$archive"

