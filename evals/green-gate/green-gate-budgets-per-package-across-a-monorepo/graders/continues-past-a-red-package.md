---
type: llm
---

The response plans quality-gate work across several packages in one repository.

PASS if both hold:

- a package whose gates stay red does not stop work on the rest — the plan keeps going
  and every package is attempted; and
- each package's own outcome is surfaced at the end, as a per-package rundown. It counts
  whether that rundown is presented as results already in hand or as the summary the run
  will produce when it finishes.

FAIL if the first package that stays red stops the whole run, or if outcomes are only
reported in aggregate with no per-package breakdown at the end.
