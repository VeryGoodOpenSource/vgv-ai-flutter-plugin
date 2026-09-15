---
type: llm
---

PASS if the example widget reads its string as `context.l10n.<key>`.

FAIL if the widget calls `AppLocalizations.of(context).<key>` at the point of use, even if an extension is declared elsewhere in the response.
