---
type: llm
---

PASS if the solution the response recommends is a ThemeExtension read off Material's ThemeData, not a custom InheritedWidget theme, and it says a parallel theme system built on InheritedWidget is the wrong approach.

FAIL if it delivers the requested InheritedWidget as the recommended implementation, or if it recommends the ThemeExtension without saying that a parallel theme system built on InheritedWidget is the wrong approach.
