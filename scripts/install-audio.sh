#!/usr/bin/env bash
set -euo pipefail

# Low-latency audio for the Ross-o-Fone native host (JUCE standalone on PipeWire's
# JACK bridge). Bootstrap runs it; --disable undoes it. Takes effect after a reboot.
#   - the user joins `pipewire`, which pipewire-bin's limits.d grants rtprio 95 + memlock;
#   - the kernel boots with preempt=full threadirqs (GRUB drop-in, appends only missing options);
#   - a oneshot system unit sets the performance CPU governor, so the CPU never clocks down mid-buffer.
# The host's 128-sample quantum is requested per run by csoundfreak's `npm run native-audio:host`
# (pw-jack -p 128); the desktop's default quantum is left alone.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mode="${1:---enable}"
grub_conf=/etc/default/grub.d/60-low-latency-audio.cfg
governor_unit=/etc/systemd/system/cpu-performance.service

case "$mode" in
    --enable)
        sudo usermod -aG pipewire "$USER"
        if ! sudo cmp -s "$ROOT/dotfiles/audio/60-low-latency-audio.cfg" "$grub_conf"; then
            sudo install -D -m 0644 "$ROOT/dotfiles/audio/60-low-latency-audio.cfg" "$grub_conf"
            sudo update-grub
        fi
        sudo install -D -m 0644 "$ROOT/dotfiles/audio/cpu-performance.service" "$governor_unit"
        sudo systemctl daemon-reload
        sudo systemctl enable --now cpu-performance.service
        printf 'Low-latency audio configured; log out for realtime limits, reboot for the kernel options.\n'
        ;;
    --disable)
        sudo gpasswd -d "$USER" pipewire || true
        if sudo test -e "$grub_conf"; then
            sudo rm -f "$grub_conf"
            sudo update-grub
        fi
        sudo systemctl disable --now cpu-performance.service || true
        sudo rm -f "$governor_unit"
        sudo systemctl daemon-reload
        printf 'The default CPU governor returns at the next reboot.\n'
        ;;
    *)
        printf 'Usage: %s [--enable|--disable]\n' "$0" >&2
        exit 2
        ;;
esac
