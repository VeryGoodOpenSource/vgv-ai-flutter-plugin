---
type: llm
---

Judge the structure shown, not whether the response recites the chain in words.

PASS if each layer depends only on the layer directly beneath it: presentation on business logic, business logic on the repository package, the repository package on the data package. The app's main_<flavor>.dart bootstrap is the one exception and may construct data clients in order to inject them into repositories; that is the expected pattern, not a violation.

FAIL if any layer reaches past the layer directly beneath it, outside that bootstrap exception.
