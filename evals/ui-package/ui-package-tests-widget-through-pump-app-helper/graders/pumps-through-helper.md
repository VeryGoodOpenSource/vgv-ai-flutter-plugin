---
type: llm
---

PASS if the widget is pumped through a reusable `pumpApp` helper that wraps it in a MaterialApp carrying the package's theme. A helper defined in the response counts, and so does one called as `tester.pumpApp(...)` on the assumption it already exists in the package's test helpers.

FAIL if each test constructs MaterialApp inline, or if the widget is pumped through some other ad hoc wrapper helper rather than a `pumpApp` helper, or is pumped with no MaterialApp around it at all.
