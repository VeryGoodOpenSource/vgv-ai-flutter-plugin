---
type: llm
---

PASS if the test mocks GoRouter and provides it to the widget tree, for example via InheritedGoRouter.

FAIL if it constructs a real router rather than a mock, whether or not that router has page builders, or if it mocks GoRouter but never provides it to the widget tree under test.
