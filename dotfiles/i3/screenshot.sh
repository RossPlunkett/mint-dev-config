#!/usr/bin/env bash
# Take a screenshot, save it to a file, AND put the PNG on the clipboard so it
# can be pasted straight into Claude Code (Ctrl+V) or any app.
#
# Usage: screenshot.sh [full|region]   (default: full)
#
# Why a file first, then the clipboard: the old `maim | xclip` pipe ran xclip
# even when maim produced nothing (region select cancelled with Esc, or an
# error). xclip then never replaced the clipboard, so a paste returned whatever
# TEXT was there before -- looking like "it pasted text, not my screenshot".
# Here we capture to a file, bail on failure WITHOUT touching the clipboard, and
# only claim the clipboard once we have real PNG bytes. The saved file also
# doubles as a fallback: reference it in Claude Code with `@` or by path if
# clipboard paste ever misbehaves.
set -euo pipefail

mode="${1:-full}"
dir="$HOME/Pictures/screenshots"
mkdir -p "$dir"
file="$dir/$(date +%F_%H-%M-%S).png"

case "$mode" in
    region) maim_args=(-s) ;;   # interactive region select
    full)   maim_args=() ;;     # whole screen
    *) echo "usage: $(basename "$0") [full|region]" >&2; exit 2 ;;
esac

# Cancelled selection / capture error -> maim exits non-zero and writes nothing.
# Bail without clobbering the clipboard.
if ! maim "${maim_args[@]}" "$file" || [ ! -s "$file" ]; then
    rm -f "$file"
    exit 0
fi

xclip -selection clipboard -t image/png -i "$file"

# Best-effort toast; harmless if no notifier is installed.
command -v notify-send >/dev/null 2>&1 &&
    notify-send -i "$file" "Screenshot copied to clipboard" "$(basename "$file")"
