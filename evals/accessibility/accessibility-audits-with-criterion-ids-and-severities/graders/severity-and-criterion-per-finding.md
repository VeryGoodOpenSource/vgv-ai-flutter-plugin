---
type: llm
---

PASS if every finding in the report carries a severity that is one of exactly CRITICAL, MAJOR, or MINOR, and cites a numeric WCAG criterion ID together with that criterion's name, for example "1.1.1 Non-text Content".

FAIL if any finding uses a severity label outside those three, or omits the criterion ID or the criterion's name.
