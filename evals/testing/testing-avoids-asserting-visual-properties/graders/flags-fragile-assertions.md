---
type: llm
---

PASS if the response includes no widget test asserting padding, background color or font size, or includes one and also states that widget tests should test behavior rather than static visual properties, or that those properties belong in golden tests.

FAIL if it hands over such a property assertion with no such caveat, for example `expect(container.color, Colors.blue)` presented as a normal widget test.
