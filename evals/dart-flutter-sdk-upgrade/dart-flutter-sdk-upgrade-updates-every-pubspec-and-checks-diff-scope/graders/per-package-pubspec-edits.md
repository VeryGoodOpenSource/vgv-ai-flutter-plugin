---
type: llm
---

PASS if the plan edits the pubspec.yaml of each of the three packages individually, and says the shared CI workflow file only needs updating once.

FAIL if the plan updates a single root pubspec, or implies one CI edit covers the pubspec constraints.
