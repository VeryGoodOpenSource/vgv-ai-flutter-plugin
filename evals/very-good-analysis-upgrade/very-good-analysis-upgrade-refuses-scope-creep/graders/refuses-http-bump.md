---
type: llm
---

PASS if the response declines to change the http dependency version as part of this change, and gives a reason: that this is a lint-compliance upgrade and an unrelated dependency bump belongs in its own change.

FAIL if the response bumps http, or agrees to bump it with a caveat attached, or declines without giving a reason.
