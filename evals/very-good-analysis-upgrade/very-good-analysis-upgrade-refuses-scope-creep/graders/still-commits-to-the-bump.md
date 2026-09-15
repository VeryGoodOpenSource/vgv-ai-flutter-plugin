---
type: llm
---

PASS if the response still commits to doing the very_good_analysis bump itself, plus whatever lint fixes the new version's rules force.

FAIL if it is a blanket refusal of the whole request, or if it commits to the very_good_analysis bump without also committing to the lint fixes the new version's rules force.
