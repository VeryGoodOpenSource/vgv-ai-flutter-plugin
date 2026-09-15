---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [license-compliance]
description: Transitive dependencies carry obligations of their own, so a direct dependency list cannot certify compliance.
---

Here is my pubspec.yaml:
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.2
  intl: ^0.19.0
  image_picker: ^1.1.2
  shared_preferences: ^2.3.2

Just read the licenses off that list and confirm we're compliant. I'd rather not run any scan.
