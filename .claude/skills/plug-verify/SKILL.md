---
name: plug-verify
description: Build and test Plug on this Mac, then post the result as a comment on the branch's pull request on GitHub, so the Claude session watching that PR can check it. Made for a Plug menu bar button (Ask Claude with the prompt /plug-verify).
argument-hint: "[branch]"
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git fetch *) Bash(git checkout *) Bash(git pull *) Bash(git log *) Bash(git branch *) Bash(swift test *) Bash(swift test) Bash(scripts/bundle.sh) Bash(sw_vers *) Bash(gh pr view *) Bash(gh pr comment *)
---

Verify Plug from this folder (the repo root, where `Package.swift` is). Branch: `$ARGUMENTS` (if empty, stay on the current branch).

1. Run `git status --short`. If files are changed, stop and say which; don't pull over someone's work, and don't post.
2. If a branch was given: `git fetch origin`, then `git checkout <branch>`. Then `git pull` (skip the pull if the branch has no upstream).
3. Run `swift test`. Note how many tests passed, or every failure with file, line and message.
4. If the tests passed, run `scripts/bundle.sh`. Note whether it finished, or every compiler error with file, line and message.
5. Find the open pull request for this branch with `gh pr view --json number,url,state`. If there is none, or it isn't open, don't post; say so.
6. Post one comment on it with `gh pr comment <number> --body-file -`, passing the report on standard input. The report:

   ```
   Mac build report for <branch> at <short commit> (`git log --oneline -1`)
   macOS <version from `sw_vers -productVersion`>, Swift <version from the first line of swift test's toolchain, if shown>

   Tests: <N passed> or <failures, each as file:line message>
   Build: <done> or <errors, each as file:line message>

   Sent by the /plug-verify command from a Plug button.
   ```

   Quote error lines exactly as the tools printed them, up to 30 lines in all. Put nothing else in the comment: no file contents, no paths outside the repo, no settings or environment variables.

Don't quit, open or relaunch Plug; this often runs from a button inside Plug. Don't edit any files and don't try to fix failures; the session watching the PR does that.

Then reply in at most four short lines: tests, build, and the link to the comment (or why nothing was posted).
