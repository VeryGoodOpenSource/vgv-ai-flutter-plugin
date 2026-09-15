---
type: llm
---

PASS if the response splits the screen into two widgets: a Page widget whose only job is to provide the bloc via BlocProvider, and a separate View widget that consumes state via BlocBuilder, BlocListener, or BlocConsumer.

FAIL if a single widget does both.
