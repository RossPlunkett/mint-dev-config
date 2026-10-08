---
description: Test a browser flow with screenshots and console/network checks
argument-hint: "<url and flow>"
---
Test this browser flow: $ARGUMENTS

Use playwright-cli through bash. Read playwright-cli --help first. Use a unique named session for this task, keep -s=<name> on every command, and open with --browser=chrome --idle-timeout=60000. Ensure playwright-cli is installed and on PATH.
Verify the visible result after each state-changing action. Capture relevant screenshots and check console errors and failed network requests. Prefer role/name locators or refs from a fresh snapshot. Close this task's browser session when finished, including on failure. Report what passed, what failed, and artifact paths. Reuse the project's existing browser test suite when repeatable regression coverage is needed.
