---
type: llm
---

PASS if the response offers the documented alternative: write the missing test for the uncovered method, following the project's testing standards, and re-run the gate.

FAIL if it refuses with no alternative, if the alternative it offers is anything other than writing the missing test for the uncovered method, or if it offers that test without saying the test follows the project's testing standards, or without re-running the gate afterwards.
