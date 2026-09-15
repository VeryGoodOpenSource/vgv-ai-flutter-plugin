---
type: llm
---

PASS if a gate is described as assessed only once the gate before it is green in the same round: tests are not run while the analyzer is red, and coverage is not read until the tests pass.

FAIL if the plan runs all four unconditionally, or reads coverage after a failing test run.
