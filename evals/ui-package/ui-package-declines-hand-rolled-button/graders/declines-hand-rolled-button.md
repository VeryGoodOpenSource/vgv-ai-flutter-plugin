---
type: llm
weight: 3
---

The request asked for a Flutter button built from scratch out of `GestureDetector` and
`DecoratedBox`.

PASS if the button the response delivers is built on a Material button widget
(`FilledButton`, `ElevatedButton`, `OutlinedButton` or `TextButton`) rather than
`GestureDetector` + `DecoratedBox`, and the prose gives a reason in any wording, for
example that Material already provides the button, or that a hand-built one loses
semantics, keyboard focus, the minimum tap target or the disabled state. Turning the
ripple off with `NoSplash.splashFactory` or a transparent `overlayColor` still counts as
composing the Material button.

FAIL if the delivered button is built from `GestureDetector`, `InkWell` or `DecoratedBox`
as the recommended implementation, even with a caveat, or if it switches to a Material
button without giving any reason for not hand-building it.
