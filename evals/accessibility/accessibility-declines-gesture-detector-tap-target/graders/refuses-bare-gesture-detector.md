---
type: llm
---

PASS if the response refuses to use a bare GestureDetector as the tap target and gives the reason, that GestureDetector is pointer-only, so the card is unreachable by keyboard or switch access.

FAIL if the response supplies the GestureDetector version as its recommendation, with or without caveats, or steers away from the bare GestureDetector without giving that reason.
