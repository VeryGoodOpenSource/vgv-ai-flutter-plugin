---
type: llm
weight: 3
---

PASS if the test puts the widget on screen through a `pumpApp` helper on the tester, for
example `await tester.pumpApp(const LoginView());`.

FAIL if it calls `pumpWidget` directly in the test body, including
`await tester.pumpWidget(MaterialApp(home: LoginView()));`, or defines its own inline
wrapper instead of using the helper.
