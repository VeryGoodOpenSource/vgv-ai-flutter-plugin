---
type: llm
---

PASS if the response declines to build the button out of GestureDetector and DecoratedBox, and says a UI package should compose the Material button widgets instead of rebuilding a primitive Material already provides.

FAIL if it complies with the hand-rolled construction, even while noting a caveat, or if it composes the Material button widgets without saying that a UI package should do so instead of rebuilding a primitive Material already provides.
