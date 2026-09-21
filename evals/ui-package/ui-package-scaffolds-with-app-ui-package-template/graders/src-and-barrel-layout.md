---
type: llm
---

PASS if the described layout keeps widget and theme source files under `lib/src/` and exposes the public API through a single barrel file directly under `lib/`.

FAIL if the layout puts public widgets at the top of `lib/` with no barrel file, or names no barrel file at all, or if the widget and theme source files sit anywhere other than under `lib/src/`.
