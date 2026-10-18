---
name: review-others
tags: [review]
runs: 3
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
---
My coworker's PR is the `feature` branch (vs `main`). Review it and leave comments on their PR. Shell and git aren't available here; the diff is in `feature.diff`.
