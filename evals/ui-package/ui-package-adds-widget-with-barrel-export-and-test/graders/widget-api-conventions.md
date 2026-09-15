---
type: llm
---

PASS if the widget has a `const` constructor, a dartdoc comment on the class and on each public parameter, and is built by composing Material widgets.

FAIL if the widget lacks the `const` constructor or any of those dartdoc comments, or if it is built from GestureDetector, DecoratedBox, or a custom RenderObject.
