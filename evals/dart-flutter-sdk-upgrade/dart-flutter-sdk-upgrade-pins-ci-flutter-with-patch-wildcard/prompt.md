---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [dart-flutter-sdk-upgrade]
description: "CI Flutter is pinned as 3.41.x, and the response explains that the wildcard is what resolves to the latest patch."
---

Bump this package's CI to Flutter 3.41.0. Here is .github/workflows/main.yaml in full:

name: ci
on: [pull_request, push]
jobs:
  build:
    uses: VeryGoodOpenSource/very_good_workflows/.github/workflows/flutter_package.yml@v1
    with:
      flutter_channel: stable

Show me the updated file and explain the version format you chose.
