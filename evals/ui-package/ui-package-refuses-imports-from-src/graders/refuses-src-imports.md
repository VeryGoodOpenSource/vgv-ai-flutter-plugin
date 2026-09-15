---
type: llm
---

PASS if the response says importing individual files from under a package's `src/` directory is wrong because everything under `src/` is private to the package, and tells the consumer to import the package's single public barrel file instead.

FAIL if it endorses the per-file imports, or treats it as a matter of taste, or if it rejects them without telling the consumer to import the package's single public barrel file instead.
