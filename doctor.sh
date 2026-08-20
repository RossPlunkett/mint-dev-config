#!/usr/bin/env bash
set -u

failures=0
check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        printf 'ok   %s\n' "$1"
    else
        printf 'MISS %s\n' "$1"
        failures=$((failures + 1))
    fi
}

for command in git node npm cmake ninja g++ i3 gnome-terminal nvim lazygit docker tailscale gh codex claude; do
    check_command "$command"
done

if command -v nvim >/dev/null 2>&1; then
    nvim_version="$(nvim --version | sed -n '1s/^NVIM v//p')"
    printf 'info Neovim %s (requires 0.11+)\n' "$nvim_version"
    if [[ "$(printf '%s\n' 0.11 "$nvim_version" | sort -V | head -n1)" != 0.11 ]]; then
        printf 'OLD  Neovim %s is below 0.11\n' "$nvim_version"
        failures=$((failures + 1))
    fi
fi

if ((failures)); then
    printf '\nDoctor found %d missing command(s).\n' "$failures" >&2
    exit 1
fi

printf '\nDevelopment toolchain checks passed.\n'
