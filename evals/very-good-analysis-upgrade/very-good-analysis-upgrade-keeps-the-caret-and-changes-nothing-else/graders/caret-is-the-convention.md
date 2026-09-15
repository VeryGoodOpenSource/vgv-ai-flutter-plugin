---
type: llm
---

PASS if the version constraint the response recommends for very_good_analysis keeps a caret (^10.0.0), and the response says the caret is the convention rather than silently pinning an exact version.

FAIL if it prints the exact pin 10.0.0 as the recommended entry, even if a caret is mentioned in passing, or if it recommends ^10.0.0 without saying the caret is the convention.
