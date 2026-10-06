#!/usr/bin/env bash
set -euo pipefail

# Ross's portrait desk layout. Do nothing when this exact set of connectors is
# unavailable so laptops, VMs, and partially connected desks can still start i3.
#
# Connector names are the proprietary NVIDIA driver's (DVI-D-0 / HDMI-0 / DP-1).
# nouveau numbered the same ports DVI-D-1 / HDMI-1 / DP-1.
required_outputs=(DVI-D-0 HDMI-0 DP-1)
connected_outputs="$(xrandr --query | awk '$2 == "connected" { print $1 }')"

for output in "${required_outputs[@]}"; do
    if ! grep -Fxq "$output" <<<"$connected_outputs"; then
        printf 'monitor-layout: %s is not connected; leaving display layout unchanged\n' "$output" >&2
        exit 0
    fi
done

# One left-to-right row. The LED display and the AOC are rotated left
# (1080 wide x 1920 tall); the Dell is landscape (1920 wide x 1080 tall):
#   HDMI-0   small LED display, vertically aligned with the AOC
#   DVI-D-0  AOC 2269W (primary)
#   DP-1     Dell U2211H, landscape, its top 5% (96px) below the AOC's top
dell_drop=96

xrandr \
    --output HDMI-0  --mode 1920x1080 --rotate left   --pos 0x0 \
    --output DVI-D-0 --mode 1920x1080 --rotate left   --pos 1080x0 --primary \
    --output DP-1    --mode 1920x1080 --rotate normal --pos "2160x${dell_drop}"
