---
type: llm
---

PASS if the shared decoration is defined inside a ThemeData as an InputDecorationTheme.

FAIL if it is extracted into a shared InputDecoration constant, a helper function, a copyWith-style extension, or a custom wrapper widget that each text field calls.
