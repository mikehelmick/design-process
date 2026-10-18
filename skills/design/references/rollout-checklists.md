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
