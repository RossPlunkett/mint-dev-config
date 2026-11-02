#!/usr/bin/env bash
set -euo pipefail

# Wallpapers for the bspwm rice. The images are Omarchy's artwork, so Git records
# only where each one lives (manifests/wallpapers.tsv, pinned to Omarchy commits).
# Each is downloaded once, scaled to at most 2976 px and given a picker thumbnail.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
themes="$HOME/.config/rice/themes"
download="$(mktemp -d)"
trap 'rm -rf "$download"' EXIT

while IFS=$'\t' read -r theme wallpaper url; do
    [[ "$theme" == \#* || -z "$theme" ]] && continue
    target="$themes/$theme/wallpapers/$wallpaper"
    [[ -s "$target" && -s "$themes/$theme/thumbs/$wallpaper" ]] && continue
    mkdir -p "$themes/$theme/wallpapers" "$themes/$theme/thumbs"
    curl -fsSL "$url" -o "$download/source"
    python3 -I - "$download/source" "$target" "$themes/$theme/thumbs/$wallpaper" <<'PY'
import sys
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
source, wallpaper, thumb = sys.argv[1:4]
image = Image.open(source).convert("RGB")
full = image.copy()
full.thumbnail((2976, 2976))
full.save(wallpaper, quality=90)
image.thumbnail((360, 203))
image.save(thumb, quality=82)
PY
    printf 'fetched %s/%s\n' "$theme" "$wallpaper"
done <"$ROOT/manifests/wallpapers.tsv"

# Render the current rice's terminal, bar, launcher and compositor files.
"$HOME/.config/rice/bin/rice-theme" --render
printf 'rendered rice %s\n' "$(cat "$HOME/.config/rice/current/name")"
