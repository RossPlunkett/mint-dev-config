# Per-machine setup checklist

The bootstrap records software and portable preferences, not application login state. Bash can load private environment values from `~/.config/mint-dev-config/private.env`, outside the repository. Keep that file mode `0600`; never reproduce its values in logs or documentation.

## Remote access prerequisite

- [ ] Install Linux Mint 22.3 x86-64 normally; leave Cinnamon installed.
- [ ] Install Tailscale on the fresh machine and join the Tailnet with `sudo tailscale up`.
- [ ] Establish SSH access: either install/enable OpenSSH server and authorize the approved public key, or enable Tailscale SSH with `sudo tailscale set --ssh` and configure the Tailnet SSH access policy. Do not copy private keys.
- [ ] Verify the remote login and sudo access before attempting bootstrap. Keep an existing access path open while changing network or session settings.

## Tool and project authentication

- [ ] Sign in to GitHub CLI with `gh auth login`; verify with `gh auth status`.
- [ ] Set Git identity: `git config --global user.name "Ross Plunkett"` and `git config --global user.email "YOUR_EMAIL"`.
- [ ] Authenticate Railway with `railway login`.
- [ ] Run Claude Code, Codex, OMP, and Pi and complete their appropriate provider/account setup. Do not copy agent auth/session databases from another workstation.
- [ ] Complete OpenCode and CodeRabbit authentication for their intended use.
- [ ] Open Android Studio, install required SDK/platform tools, accept licenses, and restore signing keys only from an approved private backup.
- [ ] If private project checkouts were deferred, rerun `./bootstrap.sh --with-projects` after GitHub login.

## Desktop and runtime acceptance

- [ ] Log out or reboot after Docker group changes; verify `docker run --rm hello-world`.
- [ ] Select **i3** at login; leave Cinnamon available as a fallback.
- [ ] Confirm GNOME Terminal's black background, blue text, Ubuntu Mono 12, 7% transparency, hidden scrollbar/bell, and hidden menubar.
- [ ] Test workspace, audio, screenshot, and automatic locking behavior. **Super+Shift+X force-kills applications.** Super+Q and the karaoke launcher are intentionally absent.
- [ ] Check CopyQ pin/tag commands; do not restore old clipboard history.
- [ ] Launch Blender and draw.io. Add any required Blender add-ons separately; no scene, add-on credential, or application session state is copied automatically.
- [ ] Test **Super+D → o → Enter** after the Ross-o-Fone checkout and OMP authentication are ready.
- [ ] Apply the optional guarded monitor script only on the matching three-monitor desk; otherwise configure that machine's displays locally.
- [ ] Run `~/mint-dev-config/doctor.sh` from an interactive terminal and resolve every `MISS` or `OLD` result.

Never add new tokens, `.env` files, SSH/private keys, Android keystores, Tailscale state, or application credential databases to this repository.
