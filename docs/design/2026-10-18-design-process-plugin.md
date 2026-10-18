# design-process plugin

Status: draft · Author: Mike Helmick · 2026-10-18

## Goal

A Claude Code plugin that encodes Mike's design process: grill hard up front, write one checked-in design doc, then build autonomously in reviewable PR stacks until the goal is met and reviews converge.

## Principles

- **P1 Collaboration over correctness.** Neither party is always right. Push back with reasons, in both directions.
- **P2 Front-load refinement.** Better input → better output. Spend time on design so the build runs with confidence.
- **P3 Small, incremental, reversible.** Break goals into phases; phases can change along the way.
- **P4 Minimal output.** One decision at a time. Minimum necessary context unless asked for more.

## Decisions

| ID | Decision |
|---|---|
| D1 | Layer on superpowers; extend, don't fork. `brainstorming` and `writing-plans` are used with this plugin's preferences layered on (grill intensity, exit gate, doc sections, locations, phase→PR grouping), so upstream improvements flow through. Only `finishing-a-development-branch` is replaced (incompatible with stacks/drafts); its safety rules are kept (green suite before integrating, never force-push unasked, careful worktree cleanup). Defers to superpowers for TDD, debugging, verification. |
| D2 | Auto-trigger on feature/design work. Classify size out loud (small / feature / subsystem); user may override. Small → few questions, in-chat spec. Feature+ → full grill, checked-in doc. |
| D3 | Goal → phases. Phase = one PR stack. Each PR is a contained unit sized for human review. |
| D4 | Stacks via `gh-stack` (`gh stack …`, agent skill `github/gh-stack`) when available. Fallback: plain git + `gh`, each PR targets its parent branch, merge bottom-up. |
| D5 | E2E validation first. Design phase checks for an e2e harness; if no obvious answer, validation approach is designed and built as phase 1. |
| D6 | Rollout plan adapts to project type: service, library, CLI, or mixed (all applicable sections). |
| D7 | One-way doors (stop and ask): persisted data, public contracts, security boundaries, new hard-to-remove dependencies, irreversible operations. All else: proceed if aligned with spec, note in PR description. |
| D8 | Grilling exit gate: goal + phases with "works when"; open questions explicitly agreed to stay open; all one-way doors decided; e2e validation per phase; **user approves the plan**. |
| D9 | Design doc at `docs/design/YYYY-MM-DD-<topic>.md`; `writing-plans` output beside it at `docs/design/YYYY-MM-DD-<topic>-plan.md`, tasks grouped by phase → PR (unless repo CLAUDE.md says otherwise). Design + plan approved together in one gate. |
| D10 | Build: open PRs as drafts; keep implementing across phases unless user input is needed (one-way door, spec contradiction, open question becomes blocking). |
| D11 | Review: full code review + security review locally **before** each PR is opened (saves CI cycles). When goal met: whole-goal code + security review, fix, repeat until converged. Converged = no blocking/high findings; nits listed in PR. |
| D12 | Watch PRs on GitHub; address comments automatically. |
| D13 | Fix, reply, and resolve threads. If a comment needs user attention (spec conflict, one-way door, judgment call): flag it, leave thread open. |
| D14 | Never mark a PR/stack ready for review without user approval. |
| D15 | Grilling style: one question per message, ordered by impact; numbered options with recommendation + reason (or "no recommendation"); running "Locked in" decision log (D1, D2…) that becomes the doc's Decisions section; I decide two-way doors myself and state them. |

## Design

```
design-process/
  .claude-plugin/plugin.json
  .claude-plugin/marketplace.json     # install from this repo
  skills/
    design/SKILL.md                   # D2, D3, D5–D9, D15; wraps brainstorming + writing-plans
      references/design-doc-template.md
      references/rollout-checklists.md
    build/SKILL.md                    # D4, D10–D14; replaces finishing-a-development-branch
  agents/
    design-security-reviewer.md       # security review of design doc (D11 design-level)
  hooks/hooks.json                    # SessionStart: precedence statement over superpowers (D1)
```

- **design skill**: entry point. Sizes the work, invokes `superpowers:brainstorming` with preferences layered on (grilling, decision log, one-way doors, doc template/location), runs design-security-reviewer, invokes `superpowers:writing-plans` with plan location + phase→PR grouping, gets one approval for both, hands off to build (not writing-plans' execution menu).
- **build skill**: executes approved doc. Per phase: create stack, TDD (superpowers), pre-open `/code-review` + `/security-review` on each PR, open drafts. At goal end: whole-goal review loop to convergence. Watch PRs with `/loop` (dynamic) polling `gh` for new comments.
- **design-security-reviewer agent**: reads the design doc; reports threats, trust boundaries, data handling, authn/z gaps. Read-only.
- **SessionStart hook**: injects a short preference statement (D1, D9 locations, build replaces finishing) so it applies in every repo.
- Reuses: `security-guidance` (commit/push security hooks), built-in `/code-review`, `/security-review`, superpowers TDD/debugging/verification.

## Phases

1. **Design skill + hook + references + design-security-reviewer.** Works when: in a scratch repo, "let's add X" triggers sizing + grilling in D15 style and produces a doc matching the template.
2. **Build skill.** Works when: an approved doc in a scratch repo produces a draft PR stack with pre-open reviews recorded in PR descriptions.

## Validation

- Structure: `claude plugin validate --strict .` on every PR.
- Hook: `tests/hook_test.sh` parses SessionStart output.
- E2E: `claude plugin eval` cases per skill (isolated runs, so skills must work without superpowers).
- Final: local install (`/plugin marketplace add <repo path>`), run each phase's "works when" in a scratch repo.

## Rollout

Type: Claude Code plugin (CLI-like).
- Install: local marketplace from this repo; later, push to GitHub and install from there.
- Upgrade: bump `version` in plugin.json; `/plugin update`.
- Downgrade: reinstall previous git tag, or disable plugin (superpowers resumes default behavior).

## Open questions (agreed to stay open)

- Code review preferences → separate skill/plugin after this ships.
