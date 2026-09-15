---
type: llm
---

PASS if the tests use blocTest from package:bloc_test with act and expect arguments.

FAIL if they are raw test() calls that subscribe to the bloc's stream manually, or if a blocTest omits the act argument or the expect argument.
