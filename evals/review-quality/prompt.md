---
name: review-quality
tags: [review]
runs: 3
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
---
Review my branch `feature` against `main` before I open a PR. Shell and git aren't available here; the diff is in `feature.diff` and the repo files are in the working tree.
