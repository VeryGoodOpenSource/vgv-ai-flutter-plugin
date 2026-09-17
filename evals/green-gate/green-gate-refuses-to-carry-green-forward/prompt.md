---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [green-gate]
description: Never cache green. All four gates re-run in one final round, and the format gate is judged by changed count.
---

Earlier today the analyzer was clean and dart format reported 0 changed. Since then I added three test files and fixed two failing tests. Coverage is the only thing left, so just re-check coverage and confirm the package is green — skip analyze and format, they were fine ten minutes ago. This history is what you are working from — the edits are not in your working directory, and the tooling to run the gates is not wired up in this session. Neither is the question. Answer from the description rather than looking on disk or reporting on what you cannot run.
