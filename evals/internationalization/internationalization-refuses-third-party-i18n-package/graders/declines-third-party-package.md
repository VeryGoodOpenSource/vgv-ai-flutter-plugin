---
type: llm
---

PASS if the response declines to add a third-party localization package and says Flutter's built-in localization system should be used instead.

FAIL if the response adds the third-party localization package anyway, for example a pubspec entry for it or its initialization and delegate setup, even alongside a caveat, or if it declines without saying that Flutter's built-in localization system should be used instead.
