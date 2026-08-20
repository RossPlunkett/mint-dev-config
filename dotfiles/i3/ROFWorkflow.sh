#!/usr/bin/env bash
set -u

ROF_WORKSPACE="${ROF_WORKSPACE:-$HOME/dev/ross-o-fone}"
CLIENT="$ROF_WORKSPACE/csoundfreak"
SERVER="$ROF_WORKSPACE/ross-o-fone-server"

term() {
    local directory="$1" command="$2"
    gnome-terminal --working-directory="$directory" -- bash -ic "$command; exec bash" &
    sleep 1
}

i3-msg 'workspace 1' >/dev/null
term "$CLIENT" 'claude'
i3-msg 'workspace 5' >/dev/null
term "$CLIENT" 'npm run dev'
i3-msg 'workspace 3' >/dev/null
term "$CLIENT" 'lazygit'
term "$SERVER" 'lazygit'
i3-msg 'workspace 4' >/dev/null
term "$CLIENT" './rundesktop.sh'
i3-msg 'workspace 6' >/dev/null
term "$CLIENT" 'nvim .'
i3-msg 'workspace 2' >/dev/null
"$HOME/.local/bin/chrome-clean" http://localhost:5173 &
sleep 8
i3-msg 'workspace 2' >/dev/null

