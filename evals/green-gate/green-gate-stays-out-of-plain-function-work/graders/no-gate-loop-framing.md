---
type: llm
---

Judge only the text of the response, not whether the merge logic is correct.

PASS if the response proposes no verify-fix-rerun loop, no coverage targets, and no sequence of analyze, format, test and coverage gates.

FAIL if it proposes any of them.
