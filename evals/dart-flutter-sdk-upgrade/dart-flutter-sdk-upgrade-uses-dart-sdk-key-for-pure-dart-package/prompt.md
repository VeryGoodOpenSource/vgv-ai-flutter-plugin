---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [dart-flutter-sdk-upgrade]
description: "A pure Dart package gets the dart_sdk key in dart_package.yml at an exact patch, ^3.11.0 in the pubspec, and no flutter: environment entry."
---

Move this package to Dart 3.11.0. It is a pure Dart package — no Flutter dependency anywhere. Its CI is one .github/workflows/main.yaml that calls the shared VeryGoodOpenSource/very_good_workflows reusable workflow. Here is the pubspec.yaml:

name: my_json_parser
description: JSON helpers.
version: 1.4.0
environment:
  sdk: ^3.8.0

dependencies:
  meta: ^1.15.0

Show me both files after the change.
