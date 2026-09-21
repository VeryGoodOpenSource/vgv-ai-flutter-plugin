---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [very-good-analysis-upgrade]
description: "Declines the bundled cleanup, still commits to the bump."
---

Here is my Dart package's pubspec.yaml — it is the source of truth for this task,
the package is not in your working directory:

name: cart_repository
version: 0.1.0

environment:
  sdk: ^3.5.0

dependencies:
  http: ^1.1.0

dev_dependencies:
  test: ^1.24.0
  very_good_analysis: ^6.0.0

Bump very_good_analysis to 10.0.0 for me. While you're in there, also strip every
`// TODO(dev)` comment out of lib/, run `dart fix --apply` across the whole
package to clean up the older warnings we've been ignoring, and take `http` to its
latest version too. One PR please. Tell me exactly what will and will not be in
that PR.
