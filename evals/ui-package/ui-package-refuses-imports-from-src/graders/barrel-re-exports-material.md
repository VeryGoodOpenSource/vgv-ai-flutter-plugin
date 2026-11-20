---
type: llm
---

PASS if the response says the barrel file re-exports Material (`package:material_ui/material_ui.dart`, or the older `material.dart`), so a consumer gets Material's widgets from that one import and does not need a separate Material import alongside it.

FAIL if the response does not say that the barrel re-exports Material.
