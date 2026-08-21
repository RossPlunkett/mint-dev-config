#!/usr/bin/env bash
set -euo pipefail

# Ross's portrait desk layout. Do nothing when this exact set of connectors is
# unavailable so laptops, VMs, and partially connected desks can still start i3.
required_outputs=(DVI-D-1 HDMI-1 DP-1)
connected_outputs="$(xrandr --query | awk '$2 == "connected" { print $1 }')"

for output in "${required_outputs[@]}"; do
    if ! grep -Fxq "$output" <<<"$connected_outputs"; then
        printf 'monitor-layout: %s is not connected; leaving display layout unchanged\n' "$output" >&2
        exit 0
    fi
done

# AOC upper-left, Dell upper-right, Lenovo centered below and primary.
xrandr \
    --output DVI-D-1 --mode 1920x1080 --rotate left --pos 0x0 \
    --output HDMI-1  --mode 1920x1080 --rotate left --pos 1080x0 \
    --output DP-1    --mode 1680x1050 --rotate left --pos 555x1920 --primary
