#!/usr/bin/env bash
set -euo pipefail

# Low-latency audio for the Ross-o-Fone native host (JUCE standalone on PipeWire's
# JACK bridge). Bootstrap runs it; --disable undoes it. Takes effect after a reboot.
#   - the user joins `pipewire`, which pipewire-bin's limits.d grants rtprio 95 + memlock;
#   - the kernel boots with preempt=full threadirqs (GRUB drop-in, appends only missing options);
#   - power-profiles-daemon runs the performance profile, so the CPU never clocks down mid-buffer.
# The host's 128-sample quantum is requested per run by csoundfreak's `npm run native-audio:host`
# (pw-jack -p 128); the desktop's default quantum is left alone.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mode="${1:---enable}"
grub_conf=/etc/default/grub.d/60-low-latency-audio.cfg

set_profile() {
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set "$1" || printf 'Could not set the %s power profile.\n' "$1" >&2
    else
        printf 'power-profiles-daemon absent; CPU governor left alone.\n'
    fi
}

case "$mode" in
    --enable)
        sudo usermod -aG pipewire "$USER"
        if ! sudo cmp -s "$ROOT/dotfiles/audio/60-low-latency-audio.cfg" "$grub_conf"; then
            sudo install -D -m 0644 "$ROOT/dotfiles/audio/60-low-latency-audio.cfg" "$grub_conf"
            sudo update-grub
        fi
        set_profile performance
        printf 'Low-latency audio configured; log out for realtime limits, reboot for the kernel options.\n'
        ;;
    --disable)
        sudo gpasswd -d "$USER" pipewire || true
        if sudo test -e "$grub_conf"; then
            sudo rm -f "$grub_conf"
            sudo update-grub
        fi
        set_profile balanced
        ;;
    *)
        printf 'Usage: %s [--enable|--disable]\n' "$0" >&2
        exit 2
        ;;
esac
