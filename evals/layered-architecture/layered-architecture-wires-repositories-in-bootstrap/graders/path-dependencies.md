---
type: llm
---

PASS if the pubspec changes reference the local repository packages with path dependencies.

FAIL if they use git or hosted pub version references, or if no pubspec entry for the local repository packages appears in the response at all.
