---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [dart-flutter-sdk-upgrade]
description: "A version-solving failure mid-bump is reported by package and clashing constraint, and the decision goes back to the user."
---

I am doing the Flutter 3.41.0 / Dart 3.11.0 bump in a checkout you do not have open, and I already changed the environment block to sdk: ^3.11.0 and flutter: ^3.41.0. Go off the error text below — flutter pub get fails:

Because my_app depends on very_good_analysis 5.1.0 which requires SDK version ^3.5.0, version solving failed.

Get me unblocked.
