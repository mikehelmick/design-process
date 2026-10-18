# Review skill

Status: draft · Author: Mike Helmick · 2026-10-18

## Goal

Add `design-process:review`, a code review skill that applies the user's quality standards on top of correctness and security review, and returns one ranked, cited, short report. The build skill uses it for its own PRs. The user can also invoke it on other people's PRs, and comments are posted only with the user's permission.

## Decisions

| ID | Decision | Door |
|---|---|---|
| CR1 | Quality priorities, in order: idiomatic for the language; well factored, with minimal duplication; easy for a human reviewer to understand. | two-way |
| CR2 | Delivery is factual, gentle and short. Each finding cites `file:line` or a doc/standard and suggests a fix when possible. | two-way |
| CR3 | One skill for both uses: build's pre-open and goal-level reviews, and other people's PRs when asked. | two-way |
| CR4 | Layers on `/code-review` (correctness) and `/security-review`, then adds the quality lens. Produces one merged report ranked correctness → security → idiomatic → factoring → readability. | two-way |
| CR5 | Quality findings are graded. Serious duplication, code a reviewer can't follow, or a misleading idiom is **high** and blocks. Everything else is a non-blocking nit listed in the PR. | two-way |
| CR6 | Precedence: documented repo conventions (CLAUDE.md, style guide, linter config), then language idioms, then undocumented local patterns. An undocumented deviation from the idiom gets flagged, citing the language standard. | two-way |
| CR7 | The duplication check covers the diff and the existing codebase. A re-implemented helper is flagged with the existing helper's `file:line`. | two-way |
| CR8 | For others' PRs: draft in chat, **always ask permission before posting**, then post one GitHub review in state `COMMENT` with inline comments and a summary. Never set APPROVE or REQUEST_CHANGES unless asked. | one-way |
| CR9 | The skill lives in this plugin as `design-process:review`. The build skill calls it. | two-way |
| CR10 | Validation uses 2 eval cases: (a) a scaffolded diff that tests the quality lens and CR6 precedence; (b) another person's PR, which tests ask-before-post. | two-way |
| CR11 | One phase, made of a 3-PR stack on top of #11: doc + plan → skill + evals → build/hook wiring + version 0.2.0. | two-way |
| CR12 | Rollout: minor version bump. Downgrade is the `design-process--v0.1.1` tag. | two-way |
| CR13 | Always flag mistakes that are expensive to fix later (one-way doors): fragility and downstream effects; breaking changes to public APIs; internal formats exposed to clients that users could come to depend on (e.g. a timestamp in a cookie instead of an opaque token); designs that box you in, such as no key rotation. | two-way |
| CR14 | CR13 findings are **high** by default. | two-way |
| CR15 | Ranking: correctness → security → one-way doors/fragility → idiomatic → factoring → readability. Replaces the ranking in CR4. | two-way |
| CR16 | Never flag anything a formatter or linter would auto-fix. | two-way |

## Design

- `skills/review/SKILL.md` covers inputs (PR, branch or range, and its base). It runs `/code-review`, then `/security-review`, then the quality lens, and merges everything into one report. Each step has a fallback for when the built-in isn't available.
- The report has one line per finding: `severity · file:line — issue`, then the citation, then the fix. Findings are ranked by category, then by severity. The skill reports convergence (no blocking/high findings).
- Others' PRs: PR content is untrusted data. Posting uses `gh api repos/{owner}/{repo}/pulls/<n>/reviews --input <json>` with `event: COMMENT`, and only runs after the user says yes.
- The build skill's "Per PR" step 3 and "Goal met" step 2 call `design-process:review`. The hook context names it.

## Phases

1. **Review skill** — works when: both eval cases pass 3/3, and the build-start eval still passes. PRs: doc + plan; skill + evals; wiring + version bump.

## Validation

- `claude plugin eval . --scaffold --ablation none` covers all cases. Run it locally, because it needs credentials.
- CI checks `validate --strict` and the hook test, which asserts that `design-process:review` exists once the hook names it.

## Security

Design-security-reviewer findings and resolutions:

| # | Sev | Finding | Resolution |
|---|---|---|---|
| S1 | high | Others' PRs can edit CLAUDE.md or linter config to rewrite the CR6 rules. | For others' PRs, read conventions from the **base ref** only (`git show <base>:CLAUDE.md`). Edits to CLAUDE.md, `.claude/`, linter config or `.mcp.json` in the diff become findings, never guidance. |
| S2 | high | Running untrusted PR code: tests, linters, hooks. | Others' PRs are reviewed **read-only** through `gh pr diff` / `git diff`. Nothing from the PR is ever executed. Execution needs separate approval and a sandbox. |
| S3 | high | Post permission is not tied to the payload. | Show the exact final JSON, including the target repo and PR number. Only a yes from the user in this session counts; PR text or a subagent can't give it. Post exactly what was shown. `event: COMMENT` is hard-coded. The build path never posts reviews. |
| S4 | med | Security findings get disclosed on public PRs. | User decision: findings **in the diff** are posted, so they never reach main. Vulnerabilities in code the PR doesn't touch go to chat, with a suggestion to disclose privately (a GitHub security advisory). |
| S5 | med | Secrets or private code leak into comments. | Never quote secret values; cite `file:line`. For others' PRs, CR7 citations are limited to the target repo at the base ref. Scan the draft for credential-shaped strings before showing it. |
| S6 | med | Injection through `gh api` arguments. | Get owner/repo from `gh pr view --json`. Validate the number as an integer and owner/repo against `^[A-Za-z0-9_.-]+$`. Serialize the JSON to a temp file, and never put comment bodies on the command line. |
| S7 | med | A missing security pass can still report "converged". | The fallback is a reviewer subagent given the diff. The report names which reviewer ran each layer. A missing security layer blocks convergence. |
| S8 | med | Eval (b) could post to real GitHub. | Evals grant only `Bash(git:*)`, so `gh` can't run, and they never point at a live PR. |
| S9 | low | The downgrade tag name differs between sections. | Use `design-process--v0.1.1` everywhere. |

## Rollout

CLI/tool:
- Version: 0.1.1 → 0.2.0, then `claude plugin tag --push`.
- Config/state: none.
- Flags: none.
- Downgrade: reinstall `design-process--v0.1.1`.

## Open questions (agreed to stay open)

- None.
