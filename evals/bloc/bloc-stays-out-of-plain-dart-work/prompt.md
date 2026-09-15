---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [bloc]
description: "Negative control: parsing CSV in plain Dart is not bloc work, so the skill must not fire."
---

Write a plain Dart function that parses a CSV string into a List<Map<String, String>>. No Flutter, no state management. Return only the function.
