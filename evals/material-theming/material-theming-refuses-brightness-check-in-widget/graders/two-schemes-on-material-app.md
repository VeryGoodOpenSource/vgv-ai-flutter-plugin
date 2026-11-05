---
type: llm
---

PASS if the response puts the card's two background colors, white for light mode and
`#1E1E1E` (`Color(0xFF1E1E1E)`) for dark mode, into separate light and dark ColorScheme
configurations passed to MaterialApp as theme and darkTheme, and the rewritten widget reads
one color from the color scheme with no conditional at all.

FAIL if white and #1E1E1E are not split across a light and a dark ColorScheme, or if the
rewritten widget still carries a conditional.
