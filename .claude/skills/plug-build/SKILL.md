---
name: plug-build
description: Build and test Plug on this Mac, optionally switching to a branch first, and report the result in a few lines. Made for a Plug menu bar button (Ask Claude with the prompt /plug-build), but works typed in Claude Code too.
argument-hint: "[branch]"
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git fetch *) Bash(git checkout *) Bash(git pull *) Bash(git log *) Bash(swift test *) Bash(swift test) Bash(scripts/bundle.sh)
---

Build Plug from this folder (the repo root, where `Package.swift` is). Branch to build: `$ARGUMENTS` (if empty, stay on the current branch).

1. Run `git status --short`. If files are changed, stop and say which; don't pull over someone's work.
2. If a branch was given: `git fetch origin`, then `git checkout <branch>`. Then `git pull` (skip the pull if the branch has no upstream).
3. Run `swift test`. If anything fails, stop and report.
4. Run `scripts/bundle.sh`. It writes `build/Plug.app`.

Don't quit, open or relaunch Plug. This often runs from a button inside Plug, and quitting it would cut this run off before it reports.

Reply in at most six short lines, plain text, no headings:
- the branch and the latest commit (`git log --oneline -1`)
- tests: how many passed, or the first failure with file and line
- build: done, or the first error with file and line
- if the build is done: "Quit Plug and open build/Plug.app to use the new build."

Don't edit any files. If something fails, report it; don't try to fix it.
