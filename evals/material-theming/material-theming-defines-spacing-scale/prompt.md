---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [material-theming]
description: An AppSpacing scale whose every step derives from one base unit, plus the rewrite that consumes it instead of raw numbers.
---

My layouts use whatever numbers I typed at the time. Here is one of them:
Padding(
  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
  child: Column(
    children: [
      const Text('Title'),
      const SizedBox(height: 13),
      const Text('Body'),
    ],
  ),
)
Give me the padding and gap convention this app should use, and rewrite this snippet inside a build method to follow it. Do not repeat the original snippet back to me.
