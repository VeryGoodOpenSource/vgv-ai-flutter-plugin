---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [green-gate]
description: Monorepo rules. Per-package iteration budget, continue-on-failure, one shared coverage target, and pubspec-walk discovery.
---

My monorepo has eight packages under packages/ plus the app at the root. Get all of them green before I open the PR. One of them, packages/legacy_sync, is at 62% coverage and is not reaching 100 this week. Walk me through how you would handle the whole set. Do not run anything yet. This layout is what you are working from — the packages are not in your working directory, so answer from the description rather than looking for them on disk.
