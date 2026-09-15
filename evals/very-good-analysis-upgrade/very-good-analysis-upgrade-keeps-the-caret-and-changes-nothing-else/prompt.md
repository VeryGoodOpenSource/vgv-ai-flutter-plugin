---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [very-good-analysis-upgrade]
description: "Writes ^10.0.0 against an explicit request to pin exactly, says the caret is the VGV convention, and touches nothing else in the pubspec."
---

Here is my package's pubspec.yaml. It is the source of truth for this task — work
from this text, not from anything on disk.

name: cart_repository
description: Cart data access for the storefront app.
version: 0.1.0

environment:
  sdk: ^3.5.0

dependencies:
  http: ^1.1.0

dev_dependencies:
  mocktail: ^1.0.0
  test: ^1.24.0
  very_good_analysis: ^6.0.0

Upgrade very_good_analysis to 10.0.0, and pin it exactly — we don't want caret
ranges. Print the full updated dev_dependencies block, then list every command
you would run, in order. Don't run anything.
