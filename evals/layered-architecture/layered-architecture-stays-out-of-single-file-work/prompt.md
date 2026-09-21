---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [layered-architecture]
description: Negative control. A one-line loop fix stays a one-line loop fix.
---

Fix the off-by-one error in this plain Dart loop:
`for (var i = 0; i <= list.length; i++) { print(list[i]); }`
Return only the corrected loop.
