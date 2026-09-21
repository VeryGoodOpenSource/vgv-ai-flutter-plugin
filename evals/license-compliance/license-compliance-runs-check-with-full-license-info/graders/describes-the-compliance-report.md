---
type: llm
---

PASS if the report keeps flagged dependencies in their own section or table, separate from
the compliant ones, and attaches a risk level to every flagged dependency, whether as a
`Risk` column or as wording such as high or medium risk per package.

FAIL if flagged and compliant dependencies sit in one undifferentiated list, if the answer
is only a pass/fail verdict or a count, or if no risk level is attached to the flagged
dependencies.
