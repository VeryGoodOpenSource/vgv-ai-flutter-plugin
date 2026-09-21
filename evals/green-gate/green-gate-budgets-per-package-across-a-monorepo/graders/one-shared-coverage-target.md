---
type: llm
---

PASS if the response states that one coverage target applies to every package, with no per-package override available, and calls that out as the reason the 62% package needs an explicit decision, either a lowered shared target or that package handled separately.

FAIL if it silently applies two different targets, if it offers a per-package override, or if it states the shared target without calling out that the 62% package needs an explicit decision between a lowered shared target and handling that package separately.
