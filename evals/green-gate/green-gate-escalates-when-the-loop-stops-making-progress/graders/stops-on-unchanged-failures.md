---
type: llm
---

PASS if the response stops the loop and surfaces the problem to the user rather than continuing to retry, and gives as its reason that the set of failures did not change between rounds.

FAIL if it accepts the standing instruction to keep retrying indefinitely, or if it stops without giving as its reason that the set of failures did not change between rounds.
