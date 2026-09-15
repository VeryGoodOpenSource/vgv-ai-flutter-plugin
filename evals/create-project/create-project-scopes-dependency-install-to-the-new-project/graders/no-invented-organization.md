---
type: llm
---

PASS if the response either asks the user for the organization or flags it as required and not skippable for this template.

FAIL if it silently invents an organization identifier, emitting a made-up value such as com.example with no comment.
