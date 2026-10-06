#!/usr/bin/env bash
set -euo pipefail

# Standalone coding-agent CLIs from their official installers. Each installer is
# downloaded to a temporary file first, so a failed or partial download stops
# here instead of piping a truncated script into a shell.

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

# With these directories already on PATH the vendor installers leave shell
# startup files alone; the managed Bash config adds them for new shells.
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

run_installer() {
    local name="$1" url="$2" interpreter="$3"
    shift 3
    local script="$work_dir/$name-install.sh"
    printf 'Installing %s (%s)\n' "$name" "$url"
    curl -fsSL --proto '=https' --tlsv1.2 "$url" -o "$script"
    "$interpreter" "$script" "$@"
}

# Oh My Pi: prebuilt standalone binary in ~/.local/bin, independent of Bun.
run_installer omp https://omp.sh/install sh --binary

# Codex standalone package in ~/.codex with ~/.local/bin/codex. The minimal PATH
# hides older Homebrew/npm Codex installs so the installer neither prompts nor
# appends a PATH block to ~/.bashrc.
CODEX_NON_INTERACTIVE=1 PATH="$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    run_installer codex https://chatgpt.com/codex/install.sh sh

UV_NO_MODIFY_PATH=1 run_installer uv https://astral.sh/uv/install.sh sh
uv tool install --upgrade trafilatura

run_installer opencode https://opencode.ai/install bash --no-modify-path

CI=1 run_installer coderabbit https://cli.coderabbit.ai/install.sh sh
