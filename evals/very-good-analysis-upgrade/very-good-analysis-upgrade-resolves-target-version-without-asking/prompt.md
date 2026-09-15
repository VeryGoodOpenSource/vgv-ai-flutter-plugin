---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [very-good-analysis-upgrade]
description: "Resolves the target version itself via the pub.dev API and lays out the bump, pub get, analyze, fix, analyze sequence in order."
---

We're due for a very_good_analysis upgrade on our Dart packages. Before you touch anything: which version will you target and how exactly will you determine it, and what is the full sequence of steps you'll take afterwards? Don't change anything yet.
