---
type: llm
---

PASS if the response states that the test tool takes a single `min_coverage` with no
per-package parameter, and resolves the 62% package explicitly rather than silently: either
by lowering the shared target, or by running that package on its own invocation with its
own target.

Running each package as a separate invocation is the documented way to give one package a
different target, so choosing it passes. What fails is claiming the tool itself accepts a
per-package value inside one recursive run.

FAIL if it applies two different targets without saying so, if it claims a per-package
`min_coverage` parameter or a per-package override within a single recursive run, or if it
states the shared target without ever resolving what happens to the 62% package.
