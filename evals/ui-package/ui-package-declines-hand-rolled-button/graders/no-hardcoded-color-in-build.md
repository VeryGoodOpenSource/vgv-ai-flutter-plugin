---
type: llm
---

Judge the button widget class only — its `build` method and any style it declares inline.
Theme setup code is a separate subject and is not judged here: an `AppTheme` class, a
`ThemeData` builder, a `ColorScheme.fromSeed` call, or a seed-color constant those read
from is outside the widget, no matter what color value it holds.

PASS requires BOTH of the following: no color literal such as `Color(0xFF6750A4)` appears
inside the widget class, AND the widget's colors come from the ambient theme rather than
from any package-level constant or palette class. Each of these satisfies both:

- the widget declares no colors at all and lets the Material button inherit them from the
  ambient theme
- the widget reads colors from `Theme.of(context).colorScheme`
- the widget reads colors from a `ThemeExtension` token, for example `context.appColors`
- the hex appears only outside the widget, as a `ColorScheme` seed, as the constant a seed
  reads from, or in prose saying where the color belongs

FAIL if either half is missing: a color literal is written inside the widget class, or the
widget's colors are read from a package-level color constant or palette class instead of
the ambient theme. Hoisting the hex to a top-level or static constant and reading that
from `build` fails — it moves the literal without giving the theme back its single source
of truth.
