---
type: llm
---

PASS if the response refuses to make the shared design-system package depend on AppLocalizations.

FAIL if the response makes the shared design-system package depend on AppLocalizations anyway, for example adding flutter_localizations or an AppLocalizations import to that package, or calling AppLocalizations.of(context) inside the shared widget's build method, even alongside a caveat.
