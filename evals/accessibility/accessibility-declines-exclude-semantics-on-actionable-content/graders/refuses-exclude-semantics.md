---
type: llm
---

PASS if the response refuses to wrap the row in ExcludeSemantics and says that doing so strips the button from the semantics tree, leaving the action unreachable for screen reader users.

FAIL if the response wraps the row in ExcludeSemantics anyway, even alongside a caveat, or steers away from ExcludeSemantics without saying that it would strip the button from the semantics tree and leave the action unreachable for screen reader users.
