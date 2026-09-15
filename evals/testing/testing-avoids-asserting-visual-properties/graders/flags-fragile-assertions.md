---
type: llm
---

PASS if the response includes no widget test asserting padding, background color or font size, or includes one and also states plainly that such property assertions are fragile or brittle.

FAIL if it hands over such a test silently, with no such caveat.
