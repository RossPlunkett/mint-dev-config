# Per-machine setup checklist

The bootstrap deliberately leaves credentials and machine-specific decisions out of Git. Complete these steps on every new workstation.

- [ ] Sign in to GitHub CLI with `gh auth login`, then verify with `gh auth status`.
- [ ] Set Git identity if this machine should create commits: `git config --global user.name "Ross Plunkett"` and `git config --global user.email "YOUR_EMAIL"`.
- [ ] Join the Tailnet with `sudo tailscale up`, then verify with `tailscale status`.
- [ ] Authenticate Railway with `railway login` if server or Sauce deployment work needs it.
- [ ] Authenticate Claude Code by running `claude` and following its sign-in flow.
- [ ] Authenticate Codex by running `codex` and following its sign-in flow.
- [ ] Configure CodeRabbit for the repositories where it is used; do not commit its credentials.
- [ ] Open Android Studio, install the required SDK/platform tools, accept licenses, and restore signing keys only from the approved private backup.
- [ ] Open T3 Code and complete its local sign-in/provider setup. Only portable keybindings are managed here.
- [ ] Confirm Docker works after logging out or rebooting: `docker run --rm hello-world`.
- [ ] Open GNOME Terminal and confirm its black background, white Ubuntu Mono 12 text, 7% transparency, hidden scrollbar/bell, and hidden menubar.
- [ ] Start i3 and test workspace, audio, browser, and `Mod+Shift+X` bindings before relying on them.
- [ ] Run `~/mint-dev-config/doctor.sh` and resolve every `MISS` or `OLD` result.

Never add tokens, `.env` files, SSH/private keys, Android keystores, Tailscale state, or application credential databases to this repository.
