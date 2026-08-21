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
expect_file README.md
expect_file AUTH_CHECKLIST.md
expect_file manifests/apt.txt
expect_file manifests/brew.txt
expect_file manifests/flatpak.txt
expect_file manifests/repositories.tsv
expect_file install-config.sh
expect_file dotfiles/bashrc
expect_file dotfiles/i3/config
expect_file dotfiles/i3/ROFWorkflow.sh
expect_file dotfiles/i3/i3KillAll.sh
expect_file dotfiles/i3/monitor-layout.sh
expect_file dotfiles/local-bin/chrome-clean
expect_file dotfiles/t3/keybindings.json
expect_file desktop/gnome-terminal.dconf
expect_file scripts/secret-scan.sh

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
    for expected in 'Docker APT repository' 'Tailscale APT repository' 'NVM + Node 22' 'Matt Pocock curated skills' 'RossPlunkett/nvim' 'npm ci' 'builddesktop.sh' 'T3 Code' 'Claude Code' 'CodeRabbit'; do
        [[ "$dry_run_output" == *"$expected"* ]] && pass "dry-run includes $expected" || fail "dry-run includes $expected"
    done
fi

expect_contains manifests/apt.txt '^i3$' 'APT manifest includes i3'
expect_contains manifests/apt.txt '^gnome-terminal$' 'APT manifest includes GNOME Terminal'
expect_contains manifests/apt.txt '^tailscale$' 'APT manifest includes Tailscale'
expect_contains manifests/apt.txt '^fzf$' 'APT manifest includes shell picker dependency'
expect_contains manifests/brew.txt '^neovim$' 'Brew manifest includes current Neovim'
expect_contains manifests/flatpak.txt '^com.github.scrivanolabs.scrivano$' 'Flatpak manifest includes Scrivano'
expect_contains manifests/flatpak.txt '^com.google.AndroidStudio$' 'Flatpak manifest includes Android Studio'
if rg -q '^node$' "$ROOT/manifests/brew.txt"; then
    fail 'Homebrew manifest does not install Node'
else
    pass 'Homebrew manifest does not install Node'
fi
if rg -q '^http-server$' "$ROOT/manifests/brew.txt"; then
    fail 'Homebrew manifest does not pull a second Node toolchain through http-server'
else
    pass 'Homebrew manifest does not pull a second Node toolchain through http-server'
fi
expect_contains lib/install.sh 'npm install --global .*http-server' 'Node tools install http-server through NVM Node'
expect_contains lib/install.sh 'CI=1 sh' 'CodeRabbit install defers interactive authentication'
expect_contains lib/install.sh '/usr/share/keyrings/tailscale-archive-keyring.gpg' 'Tailscale key matches the official repository path'
expect_contains bootstrap.sh 'github_access_ready' 'bootstrap checks GitHub access before cloning projects'
expect_contains desktop/gnome-terminal.dconf '^headerbar=@mb false$' 'GNOME Terminal hides the menubar'
expect_contains dotfiles/i3/config 'bindsym \$mod\+Shift\+x exec --no-startup-id ~/.config/i3/i3KillAll.sh' 'i3 preserves force-kill binding'
expect_contains dotfiles/i3/config '^bar \{$' 'i3 uses a valid multiline bar block'
expect_contains dotfiles/i3/config 'flatpak run com.google.AndroidStudio' 'i3 launches the installed Android Studio Flatpak'
expect_contains doctor.sh 'sort -V' 'doctor enforces the Neovim minimum version'
expect_contains README.md 'guarded three-monitor desk layout' 'README documents guarded monitor configuration'
expect_contains AUTH_CHECKLIST.md 'gh auth login' 'auth checklist covers GitHub login'

if [[ -x "$ROOT/install-config.sh" ]]; then
    fake_home="$(mktemp -d)"
    printf 'old bashrc\n' >"$fake_home/.bashrc"
    HOME="$fake_home" "$ROOT/install-config.sh" --no-dconf >/dev/null
    [[ -L "$fake_home/.bashrc" ]] && pass 'config installer links bashrc' || fail 'config installer links bashrc'
    [[ -L "$fake_home/.config/i3/config" ]] && pass 'config installer links i3 config' || fail 'config installer links i3 config'
    [[ -L "$fake_home/.config/i3/monitor-layout.sh" ]] && pass 'config installer links monitor layout' || fail 'config installer links monitor layout'
    [[ -L "$fake_home/.local/bin/chrome-clean" ]] && pass 'config installer links portable scripts' || fail 'config installer links portable scripts'
    compgen -G "$fake_home/.config-backups/*/.bashrc" >/dev/null && pass 'config installer backs up replaced files' || fail 'config installer backs up replaced files'
fi

if rg -n --hidden --glob '!.git/**' --glob '!tests/test.sh' '/home/felix|95-monitor-hotplug' "$ROOT"; then
    fail 'tracked configuration contains no machine-specific home path or obsolete hotplug rule'
else
    pass 'tracked configuration contains no machine-specific home path or obsolete hotplug rule'
fi

if command -v i3 >/dev/null 2>&1; then
    if parser_output="$(i3 -C -c "$ROOT/dotfiles/i3/config" 2>&1)"; then
        if [[ "$parser_output" == *'ERROR: CONFIG:'* ]]; then
            fail 'i3 config parses successfully'
        else
            pass 'i3 config parses successfully'
        fi
    else
        fail 'i3 config parses successfully'
    fi
fi

if rg -n --hidden --glob '!.git/**' --glob '!tests/test.sh' '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|sk-[A-Za-z0-9_-]{20,}|gh[opsu]_[A-Za-z0-9]{20,})' "$ROOT"; then
    fail 'repository contains no obvious secrets'
else
    pass 'repository contains no obvious secrets'
fi

if "$ROOT/scripts/secret-scan.sh" >/dev/null; then
    pass 'standalone secret scan passes'
else
    fail 'standalone secret scan passes'
fi

(( failures == 0 )) || exit 1
