---
type: llm
---

PASS if the response declines to change the http dependency's version as part of this change, and says why: the PR is a lint-compliance bump and unrelated dependency upgrades belong elsewhere.

FAIL if it bumps http anyway, or bumps it with a caveat attached, or if it declines without saying why: that the PR is a lint-compliance bump and unrelated dependency upgrades belong elsewhere.
