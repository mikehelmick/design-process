---
type: llm
weight: 2
---
The review flags sessionCookie exposing an internal commit timestamp to clients as something clients could come to depend on (should be an opaque token), at high severity. It does NOT flag camelCase function names as a problem (they are a documented deviation in CLAUDE.md); mentioning that they are fine is OK.
