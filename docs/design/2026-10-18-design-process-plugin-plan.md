# design-process plugin Implementation Plan

> **For agentic workers:** Execute with `design-process:build` once it exists; until then (this plan builds it), implement inline per task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ship the `design-process` Claude Code plugin: a `design` skill, a `build` skill, a design-security-reviewer agent, and a SessionStart preference hook.

**Architecture:** Markdown skills layered on superpowers (wrap `brainstorming` + `writing-plans`, replace `finishing-a-development-branch`). One static SessionStart hook injects preferences. Validated with `claude plugin validate --strict` and `claude plugin eval` cases.

**Tech Stack:** Claude Code plugin format (plugin.json, marketplace.json, skills, agents, hooks), bash, `claude plugin eval`.

**Spec:** `docs/design/2026-10-18-design-process-plugin.md`

## Global Constraints

- Plugin name `design-process`; skills `design-process:design`, `design-process:build`.
- Docs at `docs/design/YYYY-MM-DD-<topic>.md`, plan at `…-<topic>-plan.md`, unless repo CLAUDE.md says otherwise.
- Skills must work when superpowers is absent (evals run isolated; other users may not have it): name the superpowers skill to use, and state the minimum behavior if it is unavailable.
- Terse writing. One decision per message.
- No new runtime dependencies (hook is `cat` of a static JSON file).

## Review Focus

1. Superpowers not installed → design skill still grills and writes doc (eval runs isolated; case 1 covers).
2. Tiny request ("fix a typo") → sized small, no full grill (case 2).
3. Superpowers' brainstorming terminal rule ("only invoke writing-plans") vs our handoff to `build` → design skill states build replaces writing-plans' execution menu (Task 3 text).
4. `gh stack` unavailable → build falls back to git + `gh` (Task 5 text; case 3 checks it is mentioned).
5. Hook output malformed JSON → session context silently missing (Task 2 test parses it).

## File Structure

```
.claude-plugin/plugin.json            manifest
.claude-plugin/marketplace.json       local install source
hooks/hooks.json                      SessionStart → cat session-start.json
hooks/session-start.json              preference statement
skills/design/SKILL.md                design lifecycle
skills/design/references/design-doc-template.md
skills/design/references/rollout-checklists.md
skills/build/SKILL.md                 build lifecycle
agents/design-security-reviewer.md    design-level security review
evals/<case>/prompt.md + graders/*.md e2e cases
tests/hook_test.sh                    hook JSON check
README.md                             install + usage
```

---

## Stack 0 (already on branch `design/plugin-spec`)

PR 0: design doc + this plan.

## Phase 1 — Stack 1: design skill (+ hook, security reviewer it dispatches)

### PR 1 / Task 1: Plugin scaffold + marketplace

**Files:** Create `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`.

- [ ] **Step 1: Run validator to see failure**

Run: `claude plugin validate --strict .`
Expected: FAIL (no manifest).

- [ ] **Step 2: Write `.claude-plugin/plugin.json`**

```json
{
  "name": "design-process",
  "version": "0.1.0",
  "description": "Mike's software design process: grill hard up front, one checked-in design doc, then build autonomously in reviewable PR stacks.",
  "author": { "name": "Mike Helmick" },
  "license": "Apache-2.0",
  "keywords": ["design", "spec", "pr-stack", "workflow"]
}
```

- [ ] **Step 3: Write `.claude-plugin/marketplace.json`**

```json
{
  "$schema": "https://www.schemastore.org/claude-code-marketplace.json",
  "name": "design-process",
  "description": "Mike's design-and-build process for Claude Code.",
  "owner": { "name": "Mike Helmick" },
  "plugins": [
    {
      "name": "design-process",
      "description": "Grill, design doc, PR stacks, review to convergence.",
      "source": "./",
      "category": "productivity"
    }
  ]
}
```

- [ ] **Step 4: Validate**

Run: `claude plugin validate --strict . && claude plugin validate --strict .claude-plugin/marketplace.json`
Expected: PASS (fix any reported field issues inline).

- [ ] **Step 5: Commit** — `git commit -m "Add plugin and marketplace manifests"`

### PR 2 / Task 2: SessionStart preference hook

**Files:** Create `hooks/hooks.json`, `hooks/session-start.json`, `tests/hook_test.sh`.

- [ ] **Step 1: Write failing test `tests/hook_test.sh`**

```bash
#!/usr/bin/env bash
# Runs the SessionStart hook command and checks it emits valid context JSON.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cmd=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["hooks"]["SessionStart"][0]["hooks"][0]["command"])' "$root/hooks/hooks.json")
out=$(CLAUDE_PLUGIN_ROOT="$root" bash -c "$cmd")
python3 -c '
import json,sys
d=json.loads(sys.argv[1])["hookSpecificOutput"]
assert d["hookEventName"]=="SessionStart"
c=d["additionalContext"]
for s in ["design-process:design","design-process:build","finishing-a-development-branch","docs/design/"]:
    assert s in c, s
print("ok")' "$out"
```

- [ ] **Step 2: Run, expect FAIL** — `bash tests/hook_test.sh` → missing hooks.json.

- [ ] **Step 3: Write `hooks/hooks.json`**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          { "type": "command", "command": "cat \"${CLAUDE_PLUGIN_ROOT}/hooks/session-start.json\"" }
        ]
      }
    ]
  }
}
```

- [ ] **Step 4: Write `hooks/session-start.json`**

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<design-process-preferences>\nThe user's design process is installed (plugin design-process). These are user preferences and take precedence over superpowers defaults.\n- Feature, design, or non-trivial change work: invoke design-process:design FIRST. It wraps superpowers:brainstorming and superpowers:writing-plans with the user's preferences; do not run those directly for this work.\n- Design doc: docs/design/YYYY-MM-DD-<topic>.md; plan beside it as docs/design/YYYY-MM-DD-<topic>-plan.md (repo CLAUDE.md overrides).\n- After design + plan approval: invoke design-process:build. It replaces superpowers:finishing-a-development-branch and the writing-plans execution menu.\n- Still use superpowers for TDD, systematic debugging, and verification-before-completion.\n</design-process-preferences>"
  }
}
```

- [ ] **Step 5: Run test** — `bash tests/hook_test.sh` → `ok`. Then `claude plugin validate --strict .` → PASS.

- [ ] **Step 6: Commit** — `git commit -m "Add SessionStart preference hook"`

### PR 3 / Task 3: design-security-reviewer agent

**Files:** Create `agents/design-security-reviewer.md`.

- [ ] **Step 1: Write `agents/design-security-reviewer.md`**

```markdown
---
name: design-security-reviewer
description: Security review of a design doc before implementation. Use when a design doc under docs/design/ is drafted or materially changed, or when the build skill runs the goal-level review. Read-only; returns findings, not edits.
tools: Read, Grep, Glob
model: inherit
---

You review a software design doc for security before code exists. You are given its path.

Read the doc and enough of the repo to understand context. Report, ranked by severity:

1. **Trust boundaries**: what crosses them; is input validated at each?
2. **Authn/authz**: who can do what; gaps, confused-deputy risks, default-allow.
3. **Data**: sensitive data stored, logged, or transmitted; retention; encryption.
4. **Secrets**: where they live, who reads them, rotation.
5. **Abuse**: rate limits, resource exhaustion, injection surfaces, SSRF.
6. **Rollout/rollback**: does any step widen exposure (flags default-on, mixed versions)?

For each finding: severity (blocking / high / medium / low), the doc section, the risk in one sentence, a concrete fix. Mark any finding that implies a one-way door. If nothing is found in a category, say so in one line. No preamble.
```

- [ ] **Step 2: Validate** — `claude plugin validate --strict .` → PASS.
- [ ] **Step 3: Commit** — `git commit -m "Add design-security-reviewer agent"`

### PR 4 / Task 4: design skill + references + evals

**Files:** Create `skills/design/SKILL.md`, `skills/design/references/design-doc-template.md`, `skills/design/references/rollout-checklists.md`, `evals/design-feature/…`, `evals/design-small/…`.

- [ ] **Step 1: Write eval cases (failing — skill absent)**

`evals/design-feature/prompt.md`:
```markdown
---
name: design-feature
tags: [design]
runs: 2
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---
I want to add per-user API rate limiting to our service. Let's design it.
```

`evals/design-feature/graders/skill-fired.md`:
```markdown
---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?design"'
arm: both
---
```

`evals/design-feature/graders/style.md`:
```markdown
---
type: llm
weight: 2
---
The response: (1) states a size classification for the work out loud (e.g. small/bounded vs feature/architectural) and invites override; (2) asks exactly ONE question; (3) offers numbered options with a stated recommendation and reason; (4) does not write code or a spec yet. Fail if it asks multiple questions or dumps a long questionnaire.
```

`evals/design-small/prompt.md`:
```markdown
---
name: design-small
tags: [design]
runs: 2
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---
Add a --verbose flag to our CLI that turns on debug logging. Small change.
```

`evals/design-small/graders/scaled.md`:
```markdown
---
type: llm
---
The response classifies this as small/bounded, says so out loud, and keeps process light: at most one focused question or a short in-chat design for approval. Fail if it proposes a full design doc, rollout plan, multi-phase PR stack, or more than one question.
```

- [ ] **Step 2: Run evals, expect FAIL**

Run: `claude plugin eval . --tag design --no-publish --trust-plugin --max-cost-usd 5`
Expected: skill-fired fails (no design skill).

- [ ] **Step 3: Write `skills/design/SKILL.md`**

````markdown
---
name: design
description: Use when starting any feature, design, new project, or non-trivial change — before brainstorming, specs, plans, or code. Sizes the work, grills the user one decision at a time, logs decisions, flags one-way doors, writes one checked-in design doc plus plan, gets a single approval, then hands off to design-process:build.
---

# Design

The user's process. Their preferences override superpowers defaults.

## Principles

- **Collaboration over correctness.** Neither of us is always right. Push back with reasons; expect pushback.
- **Front-load refinement.** Grill hard now so the build runs automated with confidence.
- **Small, incremental, reversible.** Goal → phases → small PRs. Phases may change as we learn.
- **Minimal output.** One decision per message. Minimum necessary context unless asked.

## 1. Size it out loud

Classify and say it: **small** (bounded change to existing flow), **feature**, or **subsystem/new project**. User may override. When in doubt, go heavier.

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
````

- [ ] **Step 4: Write `skills/design/references/design-doc-template.md`**

````markdown
# <Title>

Status: draft | approved · Author: <name> · <YYYY-MM-DD>

## Goal

<One or two sentences. What is true when done.>

## Decisions

| ID | Decision | Door |
|---|---|---|
| D1 | <decision + short why> | one-way / two-way |

## Design

<Components, interfaces, data flow. Diagrams if they earn it.>

## Phases

1. **<name>** — works when: <e2e observable outcome>. PRs: <short list>.

## Validation

- Harness: <existing / built in phase 1 / how>
- Per phase: <command or scenario that proves "works when">

## Security

<design-security-reviewer findings and resolutions.>

## Rollout

<Sections from rollout-checklists.md for each applicable project type.>

## Open questions (agreed to stay open)

- <question> — <why it can stay open>
````

- [ ] **Step 5: Write `skills/design/references/rollout-checklists.md`**

````markdown
# Rollout checklists

Include every section that applies. Each item: answer or "n/a + why".

## Service

- Schema/data migrations: forward, backward, and safe to run twice?
- Feature flag: name, default, kill switch
- Rollout: canary → % → full; metrics/alerts watched at each step
- Rollback: steps, and whether data written by new code is readable by old code
- Mixed-version window: old and new running together is safe?

## Library / SDK

- Version bump (semver) and changelog
- Compatibility: what breaks for callers; deprecation path and timeline
- Supported version range of dependencies/runtimes
- Downgrade: callers pinning previous version still work?

## CLI / tool

- Release channel(s) and version bump
- Config/state file migration: forward and back
- Flags: renamed/removed flags keep a deprecated alias?
- Downgrade: older binary reads newer config/state?
````

- [ ] **Step 6: Validate + run evals**

Run: `claude plugin validate --strict . && claude plugin eval . --tag design --no-publish --trust-plugin --max-cost-usd 5`
Expected: validate PASS; both cases pass threshold. If a case fails, adjust skill wording (not the grader) and re-run.

- [ ] **Step 7: Commit** — `git commit -m "Add design skill, doc template, rollout checklists, evals"`

## Phase 2 — Stack 2: build skill

### PR 5 / Task 5: build skill + eval

**Files:** Create `skills/build/SKILL.md`, `evals/build-start/…`.

- [ ] **Step 1: Write eval case (failing)**

`evals/build-start/prompt.md`:
```markdown
---
name: build-start
tags: [build]
runs: 2
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---
The design doc and plan for the rate-limiting feature are approved. Start building. Before doing anything, tell me exactly how you'll run phase 1: how PRs are created, when reviews run, and what makes you stop and ask me.
```

`evals/build-start/graders/skill-fired.md`:
```markdown
---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?build"'
arm: both
---
```

`evals/build-start/graders/process.md`:
```markdown
---
type: llm
weight: 2
---
The response describes: PRs as a stack via gh-stack with a git + gh fallback; PRs opened as drafts; full code review and security review BEFORE each PR is opened; a whole-goal review loop to convergence at the end; watching PRs for comments; stopping only for one-way doors, spec contradictions, or blocking open questions; never marking ready-for-review without the user's approval. Pass if at least 6 of these 7 are present and none is contradicted.
```

- [ ] **Step 2: Run eval, expect FAIL** — `claude plugin eval . --tag build --no-publish --trust-plugin --max-cost-usd 5`

- [ ] **Step 3: Write `skills/build/SKILL.md`**

````markdown
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

1. `gh stack --help` works → use gh-stack (`gh stack init`, `gh stack add`, `gh stack submit`, `gh stack sync`). If `gh skill` lists `github/gh-stack`, follow it.
2. Else: plain git + `gh`. Branch each PR off the one below; `gh pr create --draft --base <parent-branch>`; merge bottom-up.

The design doc + plan are the bottom PR of the first stack.

## Per PR

1. Implement with `superpowers:test-driven-development` if available (else: failing test first). Test at multiple levels; prefer e2e functional tests.
2. `superpowers:verification-before-completion` if available: run the full suite; green before continuing.
3. **Review before opening** (saves CI cycles): run `/code-review` and `/security-review` on this PR's diff against its parent branch. Fix blocking/high findings; re-run until none.
4. Open as **draft**. If the tool can't create drafts, `gh pr ready --undo <pr>` right after. Description: what, why, decisions taken (two-way doors), review status, remaining nits.
5. Next PR.

## Watch PRs

Once the first PR is open, start `/loop` (self-paced) to poll the stack's PRs for new review comments (`gh pr view <n> --comments`, `gh api repos/{owner}/{repo}/pulls/<n>/comments`). For each comment:

- Clear fix within the doc → fix, push, reply with what changed + commit, resolve the thread.
- Needs the user (doc conflict, one-way door, judgment call) → reply with the tradeoff, leave open, flag to the user.

## Goal met

1. All phases' "works when" verified e2e.
2. Whole-goal review: `/code-review` over the full stack range, `/security-review`, and the `design-security-reviewer` agent against the doc vs what was built.
3. Fix, re-review. Repeat until **converged**: no blocking/high findings. List remaining nits in the top PR.
4. Confirm the doc's Rollout section is accurate for what shipped.
5. Report: what works (how to try it), PR links, nits, anything decided along the way.

## Never without explicit user approval

- Mark a PR or stack ready for review.
- Merge, force-push, or delete branches.

Keep `finishing-a-development-branch` safety rules: green suite before integrating; investigate rejected pushes; never remove a worktree with uncommitted files.
````

- [ ] **Step 4: Validate + run eval**

Run: `claude plugin validate --strict . && claude plugin eval . --tag build --no-publish --trust-plugin --max-cost-usd 5`
Expected: PASS.

- [ ] **Step 5: README** — replace `README.md`:

````markdown
# design-process

Claude Code plugin encoding my design process: grill hard up front, one checked-in design doc + plan, then build autonomously in reviewable draft PR stacks until reviews converge.

Layers on [superpowers](https://github.com/obra/superpowers) (recommended, not required).

## Install

```
/plugin marketplace add <path-or-github-repo>
/plugin install design-process@design-process
```

## Use

Start feature work normally ("let's add X"). `design-process:design` triggers, sizes the work, and grills. After you approve the doc + plan, `design-process:build` runs.

Design: `docs/design/2026-10-18-design-process-plugin.md`.

## Test

```
bash tests/hook_test.sh
claude plugin validate --strict .
claude plugin eval . --no-publish --trust-plugin
```
````

- [ ] **Step 6: Commit** — `git commit -m "Add build skill, eval, README"`

## Final

- [ ] Whole-goal review per build skill "Goal met".
- [ ] Local install e2e: `/plugin marketplace add /Users/mhelmick/src/design-process`, `/plugin install design-process@design-process`, new session, confirm hook context present and "let's add X" triggers `design`.
