#!/usr/bin/env bash
set -euo pipefail

# Playwright and its CLI in their own directory, reached through the wrappers in
# dotfiles/local-bin. Chromium comes from Playwright's download, not the system.
dir="$HOME/.local/share/pi-playwright"
mkdir -p "$dir"
npm install --prefix "$dir" --ignore-scripts --no-audit --no-fund --save-exact \
    @playwright/cli@0.1.22 playwright@1.63.0
"$dir/node_modules/.bin/playwright" install chromium
