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

for command in git node npm bun uv trafilatura cmake ninja g++ i3 gnome-terminal nvim lazygit docker tailscale gh codex claude omp pi railway coderabbit opencode blender drawio dot tmux btop htop ncdu ranger tig glab Xvfb yt-dlp obs kdenlive luarocks nload cava playwright-cli bspwm sxhkd polybar rofi kitty feh dunst envsubst; do
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

picom_version="$("$HOME/.local/bin/picom" --version 2>/dev/null | cut -d' ' -f1)"
if [[ "$picom_version" == v13 ]]; then
    printf 'ok   picom %s (bspwm rice)\n' "$picom_version"
else
    printf 'MISS picom v13 in ~/.local/bin (scripts/install-picom.sh)\n'
    failures=$((failures + 1))
fi

if [[ -x "$HOME/.local/kitty.app/bin/kitty" ]]; then
    printf 'ok   %s (~/.local/kitty.app)\n' "$("$HOME/.local/kitty.app/bin/kitty" --version | cut -d' ' -f1-2)"
else
    printf 'MISS kitty in ~/.local/kitty.app (scripts/install-kitty.sh)\n'
    failures=$((failures + 1))
fi

# Low-latency audio (scripts/install-audio.sh); relogin and reboot complete it.
if id -nG | grep -qw pipewire; then
    printf 'ok   pipewire group, realtime priority %s\n' "$(ulimit -r)"
elif getent group pipewire | grep -qw "$USER"; then
    printf 'info pipewire group added; log out to get realtime priority\n'
else
    printf 'MISS pipewire group (scripts/install-audio.sh)\n'
    failures=$((failures + 1))
fi
if grep -qw preempt=full /proc/cmdline && grep -qw threadirqs /proc/cmdline; then
    printf 'ok   kernel preempt=full threadirqs\n'
elif [[ -e /etc/default/grub.d/60-low-latency-audio.cfg ]]; then
    printf 'info reboot to boot with preempt=full threadirqs\n'
else
    printf 'MISS low-latency kernel options (scripts/install-audio.sh)\n'
    failures=$((failures + 1))
fi
governor="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
if [[ -z "$governor" || "$governor" == performance ]]; then
    printf 'ok   CPU governor %s\n' "${governor:-n/a (no cpufreq)}"
else
    printf 'MISS performance CPU governor, have %s (scripts/install-audio.sh)\n' "$governor"
    failures=$((failures + 1))
fi
check_command pw-jack

if ((failures)); then
    printf '\nDoctor found %d missing command(s).\n' "$failures" >&2
    exit 1
fi

printf '\nDevelopment toolchain checks passed.\n'
