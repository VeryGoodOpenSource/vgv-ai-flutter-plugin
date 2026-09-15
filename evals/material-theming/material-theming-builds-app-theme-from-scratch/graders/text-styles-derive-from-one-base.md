---
type: llm
---

PASS if the text styles are derived from a single private base TextStyle via copyWith, so fontFamily is declared once, and they are assigned to Material 3 TextTheme slot names such as bodyLarge or headlineMedium.

FAIL if they are independently declared full TextStyle constructors that each repeat fontFamily, or if they use custom slot names like heading1 or smallText.
