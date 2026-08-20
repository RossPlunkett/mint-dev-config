#!/usr/bin/env bash
wmctrl -lp | awk '{print $3}' | sort -u | while read -r pid; do
    [[ -n "$pid" && "$pid" != "0" ]] && kill -9 "$pid" 2>/dev/null || true
done
i3-msg 'workspace 1' >/dev/null

