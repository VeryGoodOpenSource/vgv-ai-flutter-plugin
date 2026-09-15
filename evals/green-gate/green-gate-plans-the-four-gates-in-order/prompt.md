---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [green-gate]
description: The plan-only path. Four gates in analyze, format, test, coverage order, each through the tool the loop actually calls.
---

Clean this package up before I open a PR — analyzer, formatting, tests and coverage all need to be green. Walk me through the plan before you touch anything: which tools you would run, in what order, and what arguments you would pass to each.
