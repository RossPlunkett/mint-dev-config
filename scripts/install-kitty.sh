#!/usr/bin/env bash
set -euo pipefail

# Current kitty into ~/.local/kitty.app, linked from ~/.local/bin. Mint's kitty (0.32)
# sends Backspace and Enter key releases as plain keypresses to programs that ask for
# release events, so Pi deleted two characters per Backspace. It stays installed for
# anything else that wants it.
app="$HOME/.local/kitty.app"
if [[ -x "$app/bin/kitty" ]]; then
    printf 'ok      %s\n' "$("$app/bin/kitty" --version | cut -d' ' -f1-2)"
else
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
fi
mkdir -p "$HOME/.local/bin"
ln -sf "$app/bin/kitty" "$app/bin/kitten" "$HOME/.local/bin/"
