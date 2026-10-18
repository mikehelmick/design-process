# design-process

Claude Code plugin encoding my design process: grill hard up front, one checked-in design doc + plan, then build autonomously in reviewable draft PR stacks until reviews converge.

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

Design: `docs/design/2026-10-18-design-process-plugin.md`.

## Test

```
bash tests/hook_test.sh
claude plugin validate --strict .claude-plugin/plugin.json
claude plugin eval . --scaffold --ablation none --no-publish --trust-plugin
```
