---
type: llm
---

PASS if the environment constraints the response writes for this package contain an `sdk:` entry only, with no `flutter:` entry alongside it. Mentioning `flutter:` solely to say it does not belong in a pure Dart package still passes.

FAIL if a Flutter constraint is actually added to the environment block.
