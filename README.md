# Mint development workstation

Rebuild Ross's development environment on a fresh Linux Mint 22.3 machine running i3. The bootstrap installs the shared toolchain, links portable configuration, and can clone and build the Ross-o-Fone and Liquid Live Karaoke workspaces.

## Install

Start from a normal Mint 22.3 installation with your user account and internet access. Bootstrap Git first because a stock Mint installation may not include it:

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/rossplunkett/mint-dev-config.git ~/mint-dev-config
cd ~/mint-dev-config
./bootstrap.sh --dry-run --with-projects
./bootstrap.sh --with-projects
```

Use `--skip-build` with `--with-projects` to clone without running `npm ci` or the initial JUCE desktop build. Running the bootstrap again is supported. Existing dotfiles are moved into timestamped directories under `~/.config-backups` before links are created.

If GitHub CLI is not authenticated, the first run installs the workstation and cleanly defers private project checkouts. Log out or reboot so the Docker group and desktop-session changes take effect, complete [AUTH_CHECKLIST.md](AUTH_CHECKLIST.md), and rerun `./bootstrap.sh --with-projects` to clone and build the projects. Then run:

```bash
./doctor.sh
```

## What it installs

- i3, GNOME Terminal, the existing i3 bindings and scripts, Bash configuration, and portable T3 Code keybindings
- PipeWire/JACK/ALSA and JUCE build dependencies
- GitHub CLI, Docker, Tailscale, Chrome, Android Studio, Scrivano, JetBrains Mono Nerd Font, and common development tools
- Homebrew CLI tools, including current Neovim and Codex
- NVM and Node 22, including `http-server`; Homebrew does not install Node
- Claude Code, Railway CLI, CodeRabbit CLI, and the current T3 Code AppImage
- `RossPlunkett/nvim` and the official main skill set from `mattpocock/skills`, linked into Claude, Codex, and shared agent skill folders
- Optional project checkouts under `~/dev/ross-o-fone` and `~/dev/liquid-live-karaoke`

Package and repository inventories live in `manifests/`. Change those files instead of editing installation commands for routine additions or removals.

## Deliberate exclusions

This repository includes Ross's guarded three-monitor desk layout. It applies only when all three expected connectors are present; otherwise it leaves the active display layout unchanged. It never copies display hotplug rules, machine identifiers, credentials, tokens, login state, Android signing keys, or T3 application state. Git identity is also left to each machine.

The curated setup excludes Nix, ESP-IDF, Kitty, Sublime Text, Pure Data/Purr Data, OBS, Audacity, Ardour, Carla, KXStudio, LADSPA/LV2 collections, Antigravity, and Graphify. Install one-off tools manually when a particular project needs them.

The existing `Mod+Shift+X` i3 force-kill binding is intentionally preserved. Treat it accordingly.

## Maintenance

Pull this repository and rerun `./bootstrap.sh` to apply configuration and tool updates. The Matt Pocock skill checkout is refreshed from its upstream repository on every run. Project repositories are not automatically pulled over local work; existing checkouts are left in place.

Run the repository checks before pushing changes:

```bash
./tests/test.sh
./scripts/secret-scan.sh
bash -n bootstrap.sh doctor.sh install-config.sh lib/install.sh scripts/*.sh tests/test.sh
```
