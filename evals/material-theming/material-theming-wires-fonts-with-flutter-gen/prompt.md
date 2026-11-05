---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [material-theming]
description: "Custom fonts follow the synced VGE theming standard: the family name comes from flutter_gen's generated FontFamily class, not a string literal."
---

Our designer sent the Inter font in three weights, Regular (400), Medium (500) and Bold (700). The .ttf files are already in assets/fonts/. Wire Inter into the app so all of its text uses it. Show the pubspec.yaml change and the Dart code, no explanation.
