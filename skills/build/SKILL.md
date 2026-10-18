---
name: build
description: Use after a design doc and plan under docs/design/ are approved, to implement them. Builds phase by phase as draft PR stacks, reviews each PR before opening, loops whole-goal code and security review to convergence, and watches PRs for comments. Replaces superpowers:finishing-a-development-branch.
---

# Build

Execute the approved doc + plan. Keep going unless the user is needed.

## Stop and ask only when

- A **one-way door** not decided in the doc appears (persisted data, public contracts, security boundaries, hard-to-remove dependencies, irreversible operations).
- The work **contradicts the doc**.
- An **open question becomes blocking**.

Everything else: decide, note it in the PR description, continue. Update the plan if phases change; say so.

## Stack tooling

1. `gh stack --help` works → use gh-stack: `gh stack init <doc-branch>` to adopt the doc branch, `gh stack add -Am "<msg>" <branch>` per PR, `gh stack submit --auto` (creates drafts), `gh stack rebase` / `gh stack sync` after fixing a lower PR.
2. Else: plain git + `gh`. Branch each PR off the one below; `gh pr create --draft --base <parent-branch>`; merge bottom-up.

The design doc + plan are the bottom PR of the first stack.

## Per PR

1. Implement with `superpowers:test-driven-development` if available (else: failing test first). Test at multiple levels; prefer e2e functional tests.
2. `superpowers:verification-before-completion` if available: run the full suite; green before continuing.
3. **Review before opening** (saves CI cycles): critical code review and security review of this PR's diff against its parent branch — `/code-review` and `/security-review`, or parallel reviewer subagents given `git diff <parent> <branch>` and the doc. Fix blocking/high findings; re-run until none. Each PR must stand alone: nothing may reference a component a higher PR adds.
4. Open as **draft**. If the tool can't create drafts, `gh pr ready --undo <pr>` right after. Description: what, why, decisions taken (two-way doors), review status, remaining nits.
5. Next PR.

## Watch PRs

Once the first PR is open, start `/loop` (self-paced) to poll the stack's PRs for new review comments (`gh pr view <n> --comments`, `gh api repos/{owner}/{repo}/pulls/<n>/comments`). For each comment:

- Clear fix within the doc → fix, push, reply with what changed + commit, resolve the thread.
- Needs the user (doc conflict, one-way door, judgment call) → reply with the tradeoff, leave open, flag to the user.

## Goal met

1. All phases' "works when" verified e2e.
2. Whole-goal review: code review over the full stack range, security review, and the `design-security-reviewer` agent on the doc vs what was built.
3. Fix, re-review. Repeat until **converged**: no blocking/high findings. List remaining nits in the top PR.
4. Confirm the doc's Rollout section is accurate for what shipped.
5. Report: what works (how to try it), PR links, nits, anything decided along the way.

## Never without explicit user approval

- Mark a PR or stack ready for review.
- Merge, force-push, or delete branches.

Keep `finishing-a-development-branch` safety rules: green suite before integrating; investigate rejected pushes; never remove a worktree with uncommitted files.
