#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

pass() { printf 'ok - %s\n' "$1"; }
fail() { printf 'not ok - %s\n' "$1" >&2; failures=$((failures + 1)); }

expect_file() {
    local path="$1"
    [[ -f "$ROOT/$path" ]] && pass "$path exists" || fail "$path exists"
}

expect_contains() {
    local path="$1" pattern="$2" label="$3"
    rg -q -- "$pattern" "$ROOT/$path" && pass "$label" || fail "$label"
}

expect_file bootstrap.sh
expect_file doctor.sh
expect_file manifests/apt.txt
expect_file manifests/brew.txt
expect_file manifests/flatpak.txt
expect_file manifests/repositories.tsv

if [[ -x "$ROOT/bootstrap.sh" ]] && "$ROOT/bootstrap.sh" --help >/dev/null; then
    pass 'bootstrap help exits successfully'
else
    fail 'bootstrap help exits successfully'
fi

if [[ -x "$ROOT/bootstrap.sh" ]]; then
    dry_run_output="$(HOME="$(mktemp -d)" "$ROOT/bootstrap.sh" --dry-run --with-projects 2>&1)" || fail 'bootstrap dry-run exits successfully'
    [[ "$dry_run_output" == *'Linux Mint 22.3'* ]] && pass 'dry-run names supported Mint release' || fail 'dry-run names supported Mint release'
    [[ "$dry_run_output" == *'csoundfreak'* ]] && pass 'dry-run includes Ross projects' || fail 'dry-run includes Ross projects'
    [[ "$dry_run_output" == *'liquid-live-karaoke-clients'* ]] && pass 'dry-run includes karaoke projects' || fail 'dry-run includes karaoke projects'
fi

expect_contains manifests/apt.txt '^i3$' 'APT manifest includes i3'
expect_contains manifests/apt.txt '^gnome-terminal$' 'APT manifest includes GNOME Terminal'
expect_contains manifests/apt.txt '^tailscale$' 'APT manifest includes Tailscale'
expect_contains manifests/brew.txt '^neovim$' 'Brew manifest includes current Neovim'
expect_contains manifests/flatpak.txt '^com.github.scrivanolabs.scrivano$' 'Flatpak manifest includes Scrivano'

if rg -n --hidden --glob '!.git/**' --glob '!tests/test.sh' '/home/felix|monitor-layout|95-monitor-hotplug' "$ROOT"; then
    fail 'tracked configuration is hardware and username independent'
else
    pass 'tracked configuration is hardware and username independent'
fi

if rg -n --hidden --glob '!.git/**' --glob '!tests/test.sh' '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|sk-[A-Za-z0-9_-]{20,}|gh[opsu]_[A-Za-z0-9]{20,})' "$ROOT"; then
    fail 'repository contains no obvious secrets'
else
    pass 'repository contains no obvious secrets'
fi

(( failures == 0 )) || exit 1
