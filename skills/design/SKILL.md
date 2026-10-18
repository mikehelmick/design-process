---
name: design
description: Use when the user asks to build, add, design, or change functionality — even when they call it small — before brainstorming, specs, plans, or code. Skip only for trivial edits (typo, rename, formatting). Sizes the work, grills the user one decision at a time, logs decisions, flags one-way doors, writes one checked-in design doc plus plan, gets a single approval, then hands off to design-process:build.
---

# Design

The user's process. Their preferences override superpowers defaults.

## Principles

- **Collaboration over correctness.** Neither of us is always right. Push back with reasons; expect pushback.
- **Front-load refinement.** Grill hard now so the build runs automated with confidence.
- **Small, incremental, reversible.** Goal → phases → small PRs. Phases may change as we learn.
- **Minimal output.** One decision per message. Minimum necessary context unless asked.

## 1. Size it out loud

Classify: **small** (bounded change to existing flow), **feature**, or **subsystem/new project**. When in doubt, go heavier. Say it with one-line reason and invite override, e.g. "**Size: feature** — <reason>. Say if you see it differently."

- Small: 0–2 questions, short in-chat design, wait for yes, then build. No doc.
- Feature+: full process below.

## 2. Grill

Use `superpowers:brainstorming` for the mechanics if available, with these overrides. If unavailable, follow this section alone.

- One question per message, ordered by impact.
- Numbered options; lead with a recommendation and one-line reason, or say "no recommendation."
- After each answer, restate a **Locked in** log: `D<n>: <decision>`. It becomes the doc's Decisions table.
- Decide two-way doors yourself; state them in the log instead of asking.
- Ask about anything one-way (below). Ask until the exit gate holds.

Must be covered before the gate:

1. **Goal** and **phases**. Each phase = one PR stack, ends working e2e, has a "works when."
2. **E2E validation.** Find the existing harness. If none or unclear, designing it is part of this design and building it is phase 1.
3. **One-way doors** decided by the user.
4. **Rollout**: project type(s) → sections from `references/rollout-checklists.md`.
5. **Open questions**: each explicitly agreed to stay open.

### One-way doors (stop and ask)

1. Persisted data: schemas, storage formats, migrations
2. Public contracts: APIs, wire protocols, CLI flags, config formats
3. Security boundaries: authn/z, secrets, trust boundaries
4. New dependencies that are expensive to remove
5. Irreversible operations: deletes, external sends, production changes

Anything else aligned with the goal: proceed, log it.

## 3. Write the doc

- Path: `docs/design/YYYY-MM-DD-<topic>.md` (repo CLAUDE.md overrides; superpowers' `docs/superpowers/specs/` is not used).
- Template: `references/design-doc-template.md`. Terse.
- Dispatch the `design-security-reviewer` agent on the doc. Fold findings into the Security section; new one-way doors go back to the user.
- Commit on a branch (not the default branch). This doc ships as the bottom PR of the first stack.

## 4. Write the plan

Use `superpowers:writing-plans` if available, with overrides:

- Save to `docs/design/YYYY-MM-DD-<topic>-plan.md`.
- Group tasks by **phase → PR**. Each PR is a contained unit sized for human review.
- Skip its execution-method menu; execution is `design-process:build`.

If unavailable: same grouping; each task lists files, tests first, exact commands.

## 5. Gate

All true, then ask for one approval of doc + plan:

- Goal + phases with "works when"
- Open questions explicitly agreed to stay open
- One-way doors decided
- E2E validation per phase
- Security review folded in

On approval → invoke `design-process:build`.
