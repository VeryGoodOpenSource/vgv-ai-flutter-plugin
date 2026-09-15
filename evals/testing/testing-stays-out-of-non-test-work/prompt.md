---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [testing]
description: "That a one-line variable rename leaves the skill dormant, since nothing else catches it firing where it should not."
---

Rename the variable `usr` to `user` in this Dart line: `final usr = getUser();` Return only the corrected line.
