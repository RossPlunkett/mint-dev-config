#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_DCONF=1
[[ "${1:-}" == "--no-dconf" ]] && APPLY_DCONF=0
BACKUP_DIR="$HOME/.config-backups/$(date +%Y%m%d-%H%M%S)"

link_file() {
    local source="$1" target="$2"
    mkdir -p "$(dirname "$target")"

    if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
        printf 'ok      %s\n' "$target"
        return
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        local relative="${target#"$HOME"/}"
        mkdir -p "$BACKUP_DIR/$(dirname "$relative")"
        mv "$target" "$BACKUP_DIR/$relative"
        printf 'backup  %s\n' "$target"
    fi

    ln -s "$source" "$target"
    printf 'linked  %s\n' "$target"
}

link_file "$ROOT/dotfiles/bashrc" "$HOME/.bashrc"
link_file "$ROOT/dotfiles/profile" "$HOME/.profile"
link_file "$ROOT/dotfiles/i3/config" "$HOME/.config/i3/config"
link_file "$ROOT/dotfiles/i3/ROFWorkflow.sh" "$HOME/.config/i3/ROFWorkflow.sh"
link_file "$ROOT/dotfiles/i3/i3KillAll.sh" "$HOME/.config/i3/i3KillAll.sh"
link_file "$ROOT/dotfiles/local-bin/chrome-clean" "$HOME/.local/bin/chrome-clean"
link_file "$ROOT/dotfiles/local-bin/karaoke-workflow" "$HOME/.local/bin/karaoke-workflow"
link_file "$ROOT/dotfiles/t3/keybindings.json" "$HOME/.t3/userdata/keybindings.json"

if ((APPLY_DCONF)); then
    if command -v dconf >/dev/null 2>&1; then
        dconf load /org/gnome/terminal/legacy/ <"$ROOT/desktop/gnome-terminal.dconf"
        printf 'loaded  GNOME Terminal profile\n'
    else
        printf 'skip    dconf is not installed\n'
    fi
fi

