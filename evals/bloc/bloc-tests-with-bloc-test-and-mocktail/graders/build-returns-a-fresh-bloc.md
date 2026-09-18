---
type: llm
weight: 3
---

Judge only the `build:` callbacks of the `blocTest` calls.

PASS if every `build:` constructs the bloc inside the callback, for example
`build: () => LoginBloc(authRepository: authRepository)` or `build: LoginBloc.new`.

FAIL if any `build:` returns a bloc that was constructed outside the callback, for example
one assigned to a variable in `setUp` and referenced as `build: () => loginBloc`.
