---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [green-gate]
description: Denominator hygiene. Generated files leave coverage via the exclude_coverage glob, and the 100 percent target holds.
---

This Flutter package is at 97% coverage. Every missing line is in lib/src/models/user.freezed.dart or lib/l10n/app_localizations.dart, both generated. My teammate wants to sprinkle coverage ignore comments through both files. What is the right way to get the coverage gate green, and what target should this package be held to?
