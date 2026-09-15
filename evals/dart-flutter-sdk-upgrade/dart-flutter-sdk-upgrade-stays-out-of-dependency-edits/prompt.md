---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [dart-flutter-sdk-upgrade]
description: "Negative control. A plain dependency add is answered without the skill and without touching the SDK constraints."
---

Add dio version 5.7.0 to this pubspec's dependencies. Return only the updated file.

name: my_app
version: 1.0.0
environment:
  sdk: ^3.9.0
  flutter: ^3.35.0

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
