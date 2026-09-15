---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [ui-package]
description: "Custom tokens as a ThemeExtension registered on ThemeData and read through a BuildContext extension, holding only what Material lacks."
---

Our UI package storefront_ui needs the design tokens Material does not have: success, warning and info colors, plus a spacing scale. Our lead wants one StorefrontTheme InheritedWidget at the app root holding all of those plus our own primary, onPrimary, surface and onSurface values, so widgets never touch ColorScheme. Show me the implementation and the StorefrontTheme.of(context) lookup our widgets would use.
