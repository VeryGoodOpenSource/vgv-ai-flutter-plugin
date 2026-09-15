---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [license-compliance]
description: The Core Standard that a project below the workspace root needs a directory argument.
---

Assume this repository layout, do not inspect the working directory, and do not run anything:
melos.yaml at the repo root, the Flutter app at mobile/ with its own pubspec.yaml, and shared packages under packages/.
I want the app's dependency licenses audited. What is the exact tool call, with every argument?
