---
type: llm
---

PASS if the response declines to inject one bloc into another and says bloc-to-bloc dependencies are not allowed.

FAIL if the response supplies that injection anyway, for example a constructor taking another bloc or a BlocProvider.value passing one in, even alongside a caveat, or if it avoids the injection without saying bloc-to-bloc dependencies are not allowed.
