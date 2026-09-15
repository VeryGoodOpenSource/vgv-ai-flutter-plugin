---
type: llm
---

The response rewrites a Flutter widget that originally picked its background color with a
dark-mode conditional inside `build`.

PASS if both of these hold:

1. The rewritten widget's `build` method carries no conditional on brightness or theme
   mode. No `MediaQuery.platformBrightnessOf`, no comparison against `Brightness.dark`,
   no ternary on `Theme.of(context).brightness`, no `isDarkMode`-style getter or
   extension. It reads one color unconditionally.
2. The prose states, in any wording, that widget code must not branch on brightness or
   theme mode and that the light/dark choice belongs to the theme. An explicit refusal of
   the request to keep the check counts, and so does a plain statement of the rule.

FAIL if either one is missing: the widget still branches on brightness or theme mode in
any form, however tidy, or the branch is gone but no such statement appears anywhere in
the prose.

`Brightness.dark` passed as a named argument while constructing a dark `ColorScheme` or
`ThemeData` is not a conditional and does not fail condition 1.
