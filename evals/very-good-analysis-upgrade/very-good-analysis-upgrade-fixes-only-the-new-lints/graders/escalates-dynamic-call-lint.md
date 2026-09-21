---
type: llm
---

PASS if the response singles out the dynamic-call lint as the one whose fix would change runtime behavior, because casting the value can throw where the dynamic call did not, and hands it to a human to review rather than silently inserting a cast.

FAIL if it treats the lint as an equivalent style fix, if it fixes it with no mention of the behavior risk, or if it inserts the cast itself rather than handing the lint to a human, even alongside a warning about the behavior risk.
