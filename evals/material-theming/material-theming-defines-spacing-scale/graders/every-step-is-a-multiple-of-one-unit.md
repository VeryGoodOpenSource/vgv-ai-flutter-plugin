---
type: llm
---

PASS if every spacing constant is expressed as a multiple of one shared base unit constant, for example `static const double sm = 0.5 * spaceUnit;`.

FAIL if each step is an independent literal number, such as `static const double sm = 8;`.
