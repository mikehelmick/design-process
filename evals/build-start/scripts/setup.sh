#!/usr/bin/env bash
# Stub approved design doc + plan so the build skill's entry check passes.
set -euo pipefail
mkdir -p docs/design
cat > docs/design/2026-01-01-rate-limiting.md <<'MD'
# Per-user rate limiting

Status: approved · Author: eval · 2026-01-01

## Goal

Limit each user to 100 requests/minute; excess gets 429.

## Phases

1. **Middleware + e2e harness** — works when: e2e test sees 429 on request 101.
MD
cat > docs/design/2026-01-01-rate-limiting-plan.md <<'MD'
# Per-user rate limiting Implementation Plan

## Phase 1 — Stack 1

### PR 1: e2e harness
### PR 2: token-bucket middleware
MD
git add docs && git -c user.email=e@x -c user.name=eval commit -qm "Add approved design"
