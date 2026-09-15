---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [dart-flutter-sdk-upgrade]
description: "With the Dart version withheld, the response cites Flutter's release archive and confirms both versions before touching files."
---

Bump this Flutter package to Flutter 3.41.0. It lives in a different checkout than the one you have open, so work from the pubspec.yaml environment block I pasted rather than anything on disk:

environment:
  sdk: ^3.9.0
  flutter: ^3.35.0

Tell me exactly what you will change before you change anything.
