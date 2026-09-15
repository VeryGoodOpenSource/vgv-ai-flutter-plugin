---
type: llm
---

Judge only the text of the response, not whether the dependency version is correct.

PASS if the response proposes no change to the Dart or Flutter SDK constraints, and raises no CI Flutter versions, SDK upgrades, or upgrade PR scope.

FAIL if it does any of those.
