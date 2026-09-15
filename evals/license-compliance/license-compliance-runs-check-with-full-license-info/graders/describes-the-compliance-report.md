---
type: llm
---

PASS if the response describes the written report the audit will produce, and that description has both of these: flagged dependencies held in their own section or table, separate from the compliant ones, and a risk level attached to every flagged dependency (a `Risk` column, or wording such as high/medium/low risk per flagged package). A blank template, a skeleton with placeholder rows, or a plain statement of what the report will contain all count. The response is describing a report it has not run yet, so it does not have to name real packages or fill in real risk levels.

FAIL only if one of those two is missing: the response describes no report at all (for example it promises only to "list the licenses" or to return a pass/fail verdict), the report it describes keeps flagged and compliant dependencies in one undifferentiated list, or the report it describes attaches no risk level to flagged dependencies.
