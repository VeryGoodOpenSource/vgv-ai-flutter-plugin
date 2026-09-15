---
type: llm
---

PASS if the response says the barrel file re-exports `material.dart`, so a consumer gets Material's widgets from that one import and does not need a separate Material import alongside it.

FAIL if the response does not say that the barrel re-exports `material.dart`.
