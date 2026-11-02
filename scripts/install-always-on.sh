#!/usr/bin/env bash
set -euo pipefail

# Opt-in, for a machine that runs agents unattended: blocks automatic sleep while
# logged in, ignores the lid and turns off Cinnamon's idle sleep. Bootstrap never runs this.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mode="${1:---enable}"
unit_dir="$HOME/.config/systemd/user"
logind_conf=/etc/systemd/logind.conf.d/50-always-on.conf
power=org.cinnamon.settings-daemon.plugins.power
keys=(sleep-inactive-ac-timeout sleep-inactive-ac-type sleep-inactive-battery-timeout sleep-inactive-battery-type)

has_cinnamon_power() { gsettings list-schemas 2>/dev/null | grep -qx "$power"; }

case "$mode" in
    --enable)
        install -D -m 0644 "$ROOT/dotfiles/systemd/keep-awake.service" "$unit_dir/keep-awake.service"
        systemctl --user daemon-reload
        systemctl --user enable --now keep-awake.service
        sudo install -D -m 0644 "$ROOT/dotfiles/systemd/logind-always-on.conf" "$logind_conf"
        sudo systemctl kill -s HUP systemd-logind
        if has_cinnamon_power; then
            gsettings set "$power" sleep-inactive-ac-timeout 0
            gsettings set "$power" sleep-inactive-ac-type nothing
            gsettings set "$power" sleep-inactive-battery-timeout 0
            gsettings set "$power" sleep-inactive-battery-type nothing
        fi
        ;;
    --disable)
        systemctl --user disable --now keep-awake.service || true
        rm -f "$unit_dir/keep-awake.service"
        systemctl --user daemon-reload
        sudo rm -f "$logind_conf"
        sudo systemctl kill -s HUP systemd-logind
        if has_cinnamon_power; then
            for key in "${keys[@]}"; do
                gsettings reset "$power" "$key"
            done
        fi
        ;;
    *)
        printf 'Usage: %s [--enable|--disable]\n' "$0" >&2
        exit 2
        ;;
esac
