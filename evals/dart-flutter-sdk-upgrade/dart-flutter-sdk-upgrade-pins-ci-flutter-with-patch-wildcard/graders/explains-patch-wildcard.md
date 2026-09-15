---
type: llm
---

PASS if the CI Flutter version is written with a literal `x` in the patch position, and the response says that wildcard is what lets CI resolve to the latest patch release automatically.

FAIL if the CI workflow carries an exact patch such as 3.41.0, or a caret such as ^3.41.0, or if the literal `x` is written with no explanation that the wildcard is what lets CI resolve to the latest patch release.
