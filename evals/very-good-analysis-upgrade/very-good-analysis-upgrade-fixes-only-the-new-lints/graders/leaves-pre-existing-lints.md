---
type: llm
---

PASS if the response leaves the two unreferenced-declaration issues in the legacy file out of this change, and gives the reason that they existed before the version bump and belong in a separate PR.

FAIL if it fixes or deletes those declarations, or leaves them out with no reason given.
