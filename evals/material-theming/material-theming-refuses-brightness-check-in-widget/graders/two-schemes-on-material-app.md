---
type: llm
---

PASS if the response puts the two background colors into separate light and dark ColorScheme configurations passed to MaterialApp as theme and darkTheme, and the rewritten widget reads one color from the color scheme with no conditional at all.

FAIL if the two colors are not split across a light and a dark ColorScheme, or if the rewritten widget still carries a conditional.
