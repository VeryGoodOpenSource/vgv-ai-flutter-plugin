---
type: llm
---

PASS if the response declines to strip the TODO comments and declines to apply a blanket automated fix across the package, on the grounds that pre-existing warnings and unrelated cleanup belong in a separate PR from the version bump.

FAIL if it agrees to either the TODO sweep or the blanket automated fix, or if it declines both without giving the grounds that pre-existing warnings and unrelated cleanup belong in a separate PR from the version bump.
