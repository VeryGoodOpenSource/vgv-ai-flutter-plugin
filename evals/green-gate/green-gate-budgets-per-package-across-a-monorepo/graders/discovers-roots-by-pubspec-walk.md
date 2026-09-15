---
type: llm
---

The response plans quality-gate work across several packages in one repository.

PASS if both hold:

- package roots are found by walking the repository for `pubspec.yaml` files; and
- that one discovered set of roots is what both the analyze step and the test step work
  over. A sentence explicitly asserting the two sets are identical is not required —
  feeding the same discovered roots into both gates is enough.

FAIL if roots come from something other than a `pubspec.yaml` walk (a hardcoded list, a
directory-name convention, or no stated method at all), or if the analyze step and the
test step are scoped to visibly different sets of packages.
