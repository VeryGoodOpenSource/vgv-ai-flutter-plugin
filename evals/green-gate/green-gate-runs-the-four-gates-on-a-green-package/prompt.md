---
max_turns: 20
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Bash, Edit, Write]
tags: [green-gate]
description: The one-pass no-op path. Drives all four gates on an already-green package and confirms green from the numbers it observed, editing nothing.
---

Check this package over before I open the PR — analyzer, formatting, tests and coverage. Run whatever you need to and tell me where it stands.
