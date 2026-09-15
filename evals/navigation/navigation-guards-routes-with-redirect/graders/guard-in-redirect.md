---
type: llm
---

PASS if the guard is implemented with GoRouter's redirect callback.

FAIL if the guard is implemented any other way, for example checking auth state inside a page's build method and pushing a route, or wrapping the guarded route's builder in a widget that swaps in the login screen.
