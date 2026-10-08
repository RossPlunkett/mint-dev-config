# Mint development workstation

Rebuild this development environment on **Linux Mint 22.3, x86-64**, with **i3 as the daily-driver session**. Keep Cinnamon installed as a fallback: the bootstrap adds i3 without removing Cinnamon or changing the login manager's session selection.

## Install

Start with a normal Mint 22.3 installation and internet access. Install Git, then clone this repository:

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/rossplunkett/mint-dev-config.git ~/mint-dev-config
cd ~/mint-dev-config
./bootstrap.sh --dry-run --with-projects
./bootstrap.sh --with-projects
```

`--with-projects` checks out the Ross-o-Fone client, server, and Sauce under `~/dev/ross-o-fone`. Use `--skip-build` to clone without running project dependency installs or the initial JUCE desktop build. Private checkouts are deferred until GitHub CLI authentication is ready; finish [AUTH_CHECKLIST.md](AUTH_CHECKLIST.md), then rerun bootstrap.

Existing configuration is backed up under `~/.config-backups` before repository links replace it. Repeat runs are supported. This is an installation recipe, not an uninstaller: excluding a tool does not remove an independently installed copy or its data from an existing machine.

Log out and select **i3** at the login screen. Log out or reboot after Docker group changes. Run `./doctor.sh` from an interactive terminal after setup.

## Recorded software

- i3, GNOME Terminal, dmenu, CopyQ, screen locking, screenshot tools, and portable Bash configuration; Cinnamon remains available.
- APT development tools, JUCE and PipeWire/JACK/ALSA dependencies, Android prerequisites, **ripgrep owned by APT**, and Docker Engine/CLI, containerd, Buildx, and Compose.
- Tailscale, Chrome, Android Studio and Scrivano (user Flatpaks).
- Homebrew Neovim, GitHub CLI, lazygit, gitui, dysk, and LuaRocks. Node and `http-server` are not declared in Homebrew.
- NVM Node 22; npm Claude Code, Railway CLI, `http-server`, Bun, and Pi (`@earendil-works/pi-coding-agent`).
- **OMP and Codex standalone installers**, OpenCode, CodeRabbit, uv, and uv-managed trafilatura.
- **Blender 5.2.2 LTS** from the official Linux x64 archive, installed outside Downloads; draw.io from its official desktop release.
- Graphviz, tmux, btop, htop, ncdu, ranger, tig, glab, Xvfb, yt-dlp, OBS Studio, Kdenlive, nload, and cava.
- JetBrains Mono Nerd Font and Courier Prime; RossPlunkett/nvim and Matt Pocock's curated agent skills.

APT, Homebrew, Flatpak, and project inventories live in `manifests/`. Other official installer recipes live in `scripts/` and `lib/install.sh`. Package-manager dependencies are not a second curated application inventory.

## CLI skills: upstream first, bundled fallback

`scripts/install-skills.sh` downloads the sources in `manifests/skills.tsv`. It prefers each requested upstream skill directory. If the download fails or that directory no longer contains `SKILL.md`, it uses the complete bundled copy in `fallback-skills/` and logs that fallback explicitly. A fallback is a recovery snapshot, not the preferred update source.

The inventory includes **bro**, **wayfinder**, **grill-me**, **Matt Pocock's tdd**, **pstack unslop**, and the installed **Caveman and Ponytail skill families**, alongside the existing Matt Pocock baseline. Source URLs, bundled snapshot provenance, and licenses are recorded in [fallback-skills/README.md](fallback-skills/README.md).

Selected copies live directly in **`~/.agents/skills`**, the one shared skill directory Pi and OMP discover automatically. No per-skill directories or links are created in `~/.pi/agent/skills` or `~/.omp/agent/skills`. Claude, Codex, and OpenCode receive compatibility links to these same shared copies, not extra copies. Existing installer-owned native links and the old backing store are retired during migration; independently managed custom skills are preserved. Downloading skill content does not execute its scripts or install the source repository's full plugin, hooks, services, or MCP integration.

To refresh only skills, run `./scripts/install-skills.sh`. To refresh bundled fallbacks, review the upstream changes and update their copies and provenance together; bootstrap never rewrites the repository's fallback snapshots.

## Pi: portable personalized setup

Bootstrap applies the complete recorded Pi profile through `scripts/install-pi.sh`. For Pi-only installation, restoration, authentication, customization inventory and verification, read **[pi/README.md](pi/README.md)**. The self-contained `pi/` package includes the Felix Night theme, OMP-style editor, working animation, visible session title and auto-namer, shared agent instructions, browser-test prompt, pinned subagents and Claude bridge configuration. Root `AGENTS.md` directs agents to this guide; runtime instructions reach Pi parents and children in any working directory. Credentials and sessions stay per machine.

This records the trusted workstation's automatic project trust and subagent authority settings; review the guide's safety notes before applying it to unfamiliar repositories. Keep the checkout in place because Pi loads its local package from here.

## Shell and desktop preferences

GNOME Terminal uses a black background, **blue text `rgb(52,71,176)`**, Ubuntu Mono 12, 7% transparency, no scrollbar/bell, and a hidden menubar. CopyQ's pin/tag command preferences are recorded; clipboard history is not.

`o` is installed in `~/.local/bin`. **Super+D → o → Enter** opens GNOME Terminal and visibly types the workspace change and OMP command through xdotool. Its default workspace is `~/dev/ross-o-fone/csoundfreak`; `ROF_WORKSPACE` changes the parent workspace and `O_KEY_DELAY_MS` changes typing speed. A failed workspace change must not launch OMP in the wrong directory. Keep focus on the new terminal while the keystrokes run.

Bash retains its caller's working directory rather than automatically entering a project. The `csf`, `rofs`, `sauce`, build/run aliases, and `cdd` picker remain. **Super+Q's old development macro and Super+G's karaoke macro are removed.**

**Super+Shift+X intentionally force-kills window-owning processes**, rather than asking applications to save or shut down. Screenshot keys remain Ctrl+Alt+S (full) and Ctrl+Alt+Shift+S (region).

`chrome-clean` remains an explicit helper. It deletes the Chrome Default profile's session-recovery data before launching Chrome; do not use it when you want session restoration.

Automatic locking remains enabled. This machine's unattended no-lock/no-blank policy is not the shared default. The guarded three-monitor desk layout script is retained as a **manual desk-specific option**, not invoked by the shared i3 startup. Run `~/.config/i3/monitor-layout.sh` only for that desk; missing expected connectors leave the active layout unchanged.

## Per-machine Blender graphics

Blender 5.2 requires newer graphics than Intel HD Graphics 4000 provides: that GPU reports OpenGL 4.2, below the [current Blender requirements](https://www.blender.org/download/requirements/). On felixpad, the default render crashed; Mesa software OpenGL successfully rendered the same scene. Software graphics retain Blender 5.2 compatibility but use CPU resources and can be substantially slower.

Enable the user-approved software launcher on that machine:

```bash
./scripts/install-blender.sh --software-rendering
```

This records a local marker at `~/.config/mint-dev-config/blender-software-rendering` and makes `~/.local/bin/blender` set `LIBGL_ALWAYS_SOFTWARE=1` only for Blender. Normal bootstrap reruns preserve the choice. Other machines use the ordinary hardware launcher by default. To return to hardware rendering after verifying compatible hardware:

```bash
./scripts/install-blender.sh --hardware-rendering
```

## Exclusions and machine state

Do not provision T3 (desktop, CLI, service, shortcuts, or URL handler), Zig, karaoke projects/workflows, Antigravity, REAPER, cmatrix, neofetch, ChatGPT desktop, Input Leap, or Steam/games. Excluded tools already present on this machine are left alone. Previously managed old workflow and T3-keybinding links are backed up when configuration is reapplied; independently managed files are not removed.

Do not copy browser profiles, clipboard history, application sessions, Docker images/volumes, Android signing keys, Tailscale state, SSH keys, or authentication databases. Provider and service sign-ins are per machine. Git identity and GPU drivers are per machine.

Private environment values belong in `~/.config/mint-dev-config/private.env`, outside this repository. The managed Bash file loads it when present. The existing OpenRouter key was moved there on felixbox and felixpad before publication; it is not included in the shared configuration. Keep this file mode `0600` and never add it to Git. Configure credentials separately on future machines.

## Remote setup over Tailscale

The new machine must first have Mint 22.3 installed, join the Tailnet, and expose an approved SSH login with sudo access. Tailnet membership alone does not provide a shell. Follow [AUTH_CHECKLIST.md](AUTH_CHECKLIST.md) for SSH or Tailscale SSH and per-machine authentication. No login state from this workstation is needed for bootstrap. Session selection and actual graphical bindings still need checking on the new machine.

## Maintenance and verification

Pull and rerun bootstrap to apply selected tools and configuration. Existing project checkouts are not automatically pulled over local work. Existing non-symlink skills are preserved. Changing the package inventories does not uninstall software.

```bash
./tests/test.sh
./tests/test-pi.sh
node tests/test-pi-extensions.mjs  # requires installed Pi peers; no model calls
bash -n bootstrap.sh doctor.sh install-config.sh lib/install.sh scripts/*.sh tests/test.sh
./scripts/secret-scan.sh
```

Behavior checks exercise dry-run isolation, configuration backup/idempotence, retirement of owned links, shared-skill migration, and shell working-directory preservation. The secret scanner reports matching file names without printing potential secret values; it detects only selected patterns and is not a complete credential audit.
