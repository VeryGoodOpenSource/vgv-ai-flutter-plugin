---
type: llm
---

PASS if the response declines to use GoRouter's extra parameter.

FAIL if the response routes the object through extra anyway, for example a call passing extra: product or a cast of GoRouterState.extra at the destination, even alongside a caveat.
