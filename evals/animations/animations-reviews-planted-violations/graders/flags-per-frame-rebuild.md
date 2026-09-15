---
type: llm
---

PASS if the review states that the expensive child widget is rebuilt on every frame and should be passed through AnimatedBuilder's child parameter instead of being constructed inside the builder callback.

FAIL if the review does not raise the per-frame rebuild of the expensive child, or does not point to AnimatedBuilder's child parameter as the fix.
