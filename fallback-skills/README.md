# Bundled fallback skills

`scripts/install-skills.sh` installs the skills listed in `manifests/skills.tsv`
(`source-id`, `clone-url`, `upstream-subdir`, `skill-name`). It always tries a
fresh clone of each upstream repository first and installs the upstream
directory. The copies here are used only for a skill whose upstream download
fails or whose upstream directory no longer contains `SKILL.md`. Upstream is
the source of truth; these files are an offline safety net and go stale.

Layout: `fallback-skills/<source-id>/<skill-name>/` is the complete skill
directory with symlinks dereferenced (this tree contains no symlinks), and
`fallback-skills/<source-id>/LICENSE` is the upstream license. Skill files are
copied unmodified.

Snapshot taken 2026-10-06 from copies already on the workstation. No snapshot
was cloned for this purpose, so each source below records exactly which local
copy it came from and which upstream commit that copy matches, where known.

## matt

- Upstream: https://github.com/mattpocock/skills.git
- Skills: the 25 directories listed in `.claude-plugin/plugin.json`
  (plugin `mattpocock-skills` 1.2.3), the same set the old
  `scripts/install-matt-skills.sh` linked. Includes `tdd`, `wayfinder`,
  `grill-me` and `resolving-merge-conflicts`.
- Snapshot: `git archive` of commit
  `959a8e9f1edc3adbe2f7e3054bb6fbefa6696260` (2026-09-15T15:28:46+01:00) from
  the local checkout `~/.local/share/mattpocock-skills`. Taken from the commit,
  not the working tree, so a local edit to `handoff/SKILL.md` and personal
  untracked files under `teach/` are excluded.
- License: MIT, `matt/LICENSE` from the same commit.

## caveman

- Upstream: https://github.com/JuliusBrussee/caveman.git, `skills/<name>`
- Skills: all 20 skills registered from `JuliusBrussee/caveman` in
  `~/.agents/.skill-lock.json`: `cavecrew`, `caveman`, `caveman-commit`,
  `caveman-compress`, `caveman-discover`, `caveman-evidence-review`,
  `caveman-explore`, `caveman-help`, `caveman-learn`, `caveman-manage`,
  `caveman-optimize`, `caveman-review`, `caveman-setup`, `caveman-stats`,
  `investigate-first`, `lean-build`, `migration`, `safe-refactor`,
  `surgical-patch`, `verify-and-stop`.
- Snapshot: copied from the installed directories in `~/.agents/skills`
  (installed 2026-09-17 by the `skills` CLI). There is no local caveman
  checkout and the lock file does not record an upstream commit, so the exact
  commit is unknown. Each copied directory's git tree hash matches the
  `skillFolderHash` the lock file recorded for it from upstream, so the files
  are byte-identical to an upstream `skills/<name>` tree.
- License: `caveman/LICENSE` (Apache-2.0), `caveman/NOTICE`,
  `caveman/LICENSE-MIT` and `caveman/LICENSING.md`, fetched from upstream
  `main` on 2026-10-06 (HEAD `99aafe151a1be72be783e662858e8a0955add59f`).
  Upstream is Apache-2.0 from Caveman 3.0.0; earlier releases of the skill
  files were MIT. The snapshot's release is unknown, so both texts are kept.

## ponytail

- Upstream: https://github.com/DietrichGebert/ponytail.git, `skills/<name>`
- Skills: all six directories in `skills/`: `ponytail`, `ponytail-audit`,
  `ponytail-debt`, `ponytail-gain`, `ponytail-help`, `ponytail-review`.
- Snapshot: `git archive` of commit
  `e3ba2aa6f1e6f0bc4d69eb09c9f0d0a93af56156` (2026-09-14T16:34:42+02:00) from
  the local checkout `~/.pi/agent/git/github.com/DietrichGebert/ponytail`.
- License: `ponytail/LICENSE` from the same commit.

## pstack

- Upstream: https://github.com/cursor/plugins.git, `pstack/skills/<name>`
- Skills: `bro`, `unslop`. pstack's own `tdd` and `teach` are not included;
  those names come from `matt`.
- `bro`: `git archive` of commit `2d7c6569301f2aee62323e6067e09951131fbb3b`
  (2026-09-26T15:34:32-05:00) from the local sparse checkout
  `~/.local/share/cursor-plugins`.
- `unslop`: copied from the installed directory `~/.agents/skills/unslop`
  (dated 2026-09-26), not from the checkout. It differs from `unslop` at
  `2d7c656` by one extra step in "Process" (`3. Self-audit: ...`). The local
  history is too shallow to tell whether that line came from an older upstream
  version or a local edit. An online install uses current upstream instead.
- License: MIT, `pstack/LICENSE` (`pstack/LICENSE` at `2d7c656`).

## Limitations of a standalone skill copy

A fallback installs only the skill directory, not the plugin or repository
around it. Only the files inside each skill directory are bundled.

- Relative links in caveman `README.md`/`CLAUDE.md` files that point outside
  the skill (`../../README.md`, `../../docs/...`, `../../cli/...`) are broken.
  Skills do not need these links to work.
- `cavecrew` delegates to the `cavecrew-investigator`, `cavecrew-builder` and
  `cavecrew-reviewer` agents, which come with the caveman plugin and are not
  bundled. `caveman-discover`, `caveman-learn`, and the Caveman Cloud skills
  (`caveman-setup`, `caveman-stats`, `caveman-manage`, `caveman-optimize`,
  `caveman-evidence-review`) expect the caveman CLI or cloud service.
  `caveman-compress` needs `python3` to run its bundled `scripts/`.
- `ponytail-gain` cites the repository's `benchmarks/` and README. Ponytail's
  hooks, commands, MCP server and editor extensions are not installed.
- pstack's agents, automations and the other pstack skills are not installed.
  `bro` and `unslop` set `disable-model-invocation: true`, so they run only
  when invoked explicitly.
- Plugin manifests (`.claude-plugin/plugin.json` and similar) are not copied,
  so plugin-level metadata, versions and auto-update do not apply.
