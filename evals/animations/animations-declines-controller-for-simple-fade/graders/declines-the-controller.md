---
type: llm
---

PASS if the response declines to build this with an AnimationController and says an implicit animation is the simpler approach that is sufficient here.

FAIL if the response supplies the AnimationController version anyway, for example a StatefulWidget with a ticker provider mixin driving an AnimatedBuilder, even alongside a caveat, or if it avoids the controller without saying an implicit animation is the simpler approach that is sufficient here.
