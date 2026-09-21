---
type: llm
---

PASS if the grouping covers only the two static Text children, so the label and the amount are announced as one node, while the ElevatedButton remains its own independently focusable node outside the grouping.

FAIL if the fix puts the button inside the MergeSemantics, or wraps the whole Row.
