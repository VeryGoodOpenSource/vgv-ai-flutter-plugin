---
type: llm
---

PASS if the response declines to make one repository depend on another.

FAIL if the response wires that dependency anyway, for example adding the other repository package to the repository's pubspec dependencies or taking a UserRepository in OrderRepository's constructor, even alongside a caveat.
