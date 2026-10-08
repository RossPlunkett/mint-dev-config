# Workstation configuration

For Pi installation, restoration, UI customization, model/authentication setup, subagents, Claude bridge, browser testing, or Pi failures: **read `pi/README.md` before editing or advising**. The portable profile is in `pi/`; `scripts/install-pi.sh` applies it. Runtime agent instructions are `pi/instructions/*.md`, loaded for parents and children. Keep settings, installer behavior, docs and focused tests consistent.

Before pushing changes, run `tests/test.sh`, `tests/test-pi.sh`, shell syntax checks and `scripts/secret-scan.sh`. For Pi extension changes also run `node tests/test-pi-extensions.mjs` against installed Pi peers. Report separately anything requiring interactive login, model calls, desktop or browser acceptance.

Preserve existing user config with backups. Keep credentials, auth databases, model caches, sessions, run artifacts, private environment values and machine identifiers outside Git. `AUTH_CHECKLIST.md` owns per-machine sign-ins. Dry-run bootstrap must leave HOME untouched.
