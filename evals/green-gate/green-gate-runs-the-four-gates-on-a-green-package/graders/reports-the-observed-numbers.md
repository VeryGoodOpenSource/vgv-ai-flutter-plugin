---
type: llm
---

PASS if the reply reports the package as green and backs it with numbers taken from this
run: no analyzer errors, zero files changed by the formatter, every test passing, and
coverage at 100%.

FAIL if it declares the package green without the formatter's changed count, or without a
coverage percentage, or if a number it reports contradicts the gate it belongs to — for
example calling coverage green while naming a figure below 100%.
