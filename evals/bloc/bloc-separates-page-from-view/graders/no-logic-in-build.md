---
type: llm
---

PASS if no business logic or repository calls appear inside a widget's build method, and widgets only read state and dispatch events.

FAIL if a build method calls a repository or performs business logic.
