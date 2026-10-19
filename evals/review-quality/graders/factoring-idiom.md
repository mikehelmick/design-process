---
type: llm
weight: 2
---
The review flags that app/posts.py re-implements the existing helper makeSlug in app/text.py (citing app/text.py) and suggests calling it, AND flags at least one non-idiomatic Python construct (e.g. `for i in range(len(...))` or string concatenation in a loop) with a suggested fix.
