---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [dart-flutter-sdk-upgrade]
description: "Monorepo plan: every package's pubspec edited individually, the shared CI workflow once, pub get and analyze per package, then the diff scope check."
---

Monorepo, moving everything to Flutter 3.41.0 (Dart 3.11.0). It has packages/api_client (pure Dart, no Flutter dependency), packages/app_ui (a Flutter package), and apps/mobile (the Flutter app), plus a single .github/workflows/main.yaml calling the shared VeryGoodOpenSource /very_good_workflows workflows. Walk me through the change: which files you edit, what you run to verify it, and how you check the PR before opening it. Do not edit anything yet.
