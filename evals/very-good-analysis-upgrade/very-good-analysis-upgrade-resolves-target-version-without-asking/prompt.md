---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [very-good-analysis-upgrade]
description: "Resolves the target version itself via the pub.dev API and lays out the bump, pub get, analyze, fix, analyze sequence in order."
---

We're due for a very_good_analysis upgrade on our Dart packages. Those packages are not in your working directory, so answer from this description rather than inspecting what is on disk. Before you touch anything: which version will you target and how exactly will you determine it, and what is the full sequence of steps you'll take afterwards? Describe the procedure you would follow with your normal tooling available; do not tell me what this session cannot reach. Don't change anything yet.
