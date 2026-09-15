---
type: llm
---

PASS if data clients and repositories are constructed in a main entrypoint file and passed into the App widget, which provides them to the tree.

FAIL if they are constructed anywhere else, or are not passed into the App widget that provides them to the tree.
