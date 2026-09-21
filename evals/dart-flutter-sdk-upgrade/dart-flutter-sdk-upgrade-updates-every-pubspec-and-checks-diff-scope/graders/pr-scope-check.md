---
type: llm
---

PASS if before opening the PR the response checks that the changed-file list contains only workflow YAML files and pubspec.yaml files, and states that anything else appearing in the diff does not belong in this PR.

FAIL if it does not make that check, or does not say that anything else in the diff does not belong.
