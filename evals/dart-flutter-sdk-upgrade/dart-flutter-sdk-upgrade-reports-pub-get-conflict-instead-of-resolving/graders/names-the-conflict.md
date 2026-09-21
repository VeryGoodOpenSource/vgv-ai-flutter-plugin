---
type: llm
---

PASS if the response reports the conflict specifically, naming the package involved and the SDK constraint that clashes.

FAIL if it only says that dependency resolution failed, or if it names the package without the SDK constraint that clashes, or the constraint without the package.
