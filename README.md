# Design Process

Claude Code plugin encoding a software design process: grill hard up front, one checked-in design doc + plan, then build autonomously in reviewable draft PR stacks until reviews converge.

Layers on [superpowers](https://github.com/obra/superpowers) (recommended, not required).

## Install

```
/plugin install design-process --marketplace mikehelmick/design-process
```

Local checkout:

```
/plugin marketplace add /path/to/design-process
/plugin install design-process@design-process
```

## Use

Start feature work normally ("let's add X"). `design-process:design` triggers, sizes the work, and grills. After you approve the doc + plan, `design-process:build` runs.

`design-process:review` reviews any PR, branch or diff, layering idiomatic/factoring/readability and one-way-door checks on correctness, security and static analysis. For others' PRs it drafts and asks before posting.

Design: `docs/design/2026-10-18-design-process-plugin.md`.

## Test

CI (`.github/workflows/ci.yml`) runs the hook test and `validate`. Evals need Claude credentials and cost per run, so run them locally:

```
bash tests/hook_test.sh
for t in .claude-plugin/plugin.json .claude-plugin/marketplace.json skills agents; do claude plugin validate --strict "$t"; done
claude plugin eval . --scaffold --ablation none --no-publish --trust-plugin --allow-tools 'Bash(git:*)' --judge-model sonnet
```

## Releasing

Installs are cached by version, so unbumped changes may not reach users.

1. In the PR, bump `version` in `.claude-plugin/plugin.json` (semver: patch for wording/fixes, minor for new behavior).
2. Merge to `main`.
3. Tag: `claude plugin tag --push` (creates `design-process--v<version>`; checks manifests agree).
4. Users update: `/plugin marketplace update design-process`, then `/plugin update design-process`.

Downgrade: reinstall from a previous `design-process--v<version>` tag, or disable the plugin.
