---
max_turns: 20
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill]
tags: [license-compliance]
description: The license check is scoped to the app subdirectory of a monorepo rather than run at the repo root.
---

Assume this repository layout and answer from it rather than inspecting the working directory: melos.yaml at the repo root, the Flutter app at mobile/ with its own pubspec.yaml, and shared packages under packages/. Audit the app's dependency licenses.
