#!/usr/bin/env bash
set -euo pipefail

# picom v13 into ~/.local, for the bspwm rice's window animations. Mint's own picom
# (v10) has no animations and crashed during rice switches; it stays installed for
# anything else that wants it. meson builds its own libconfig, since Mint ships 1.5
# and picom needs 1.7, so cmake and git must be present.
version=v13
if [[ "$("$HOME/.local/bin/picom" --version 2>/dev/null)" == "$version "* ]]; then
    printf 'ok      picom %s\n' "$version"
    exit 0
fi
src="$HOME/.local/src/picom"
rm -rf "$src"
mkdir -p "$(dirname "$src")"
git clone --quiet --depth 1 --branch "$version" https://github.com/yshui/picom.git "$src"
meson setup --buildtype=release --prefix="$HOME/.local" "$src/build" "$src"
ninja -C "$src/build"
ninja -C "$src/build" install
printf 'built   picom %s\n' "$version"
