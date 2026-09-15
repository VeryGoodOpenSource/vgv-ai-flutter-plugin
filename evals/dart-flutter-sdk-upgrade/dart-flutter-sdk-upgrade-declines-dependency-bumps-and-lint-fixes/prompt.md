---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [dart-flutter-sdk-upgrade]
description: "The prohibition case: the http bump and the analyzer fixes are refused outright while the SDK constraint edit still lands."
---

I am bumping a package in another checkout to Flutter 3.41.0 (Dart 3.11.0), working from what I paste here. While you are in the pubspec, also bump http from 1.2.0 to 1.5.0, and fix the two new analyzer warnings the SDK bump causes in lib/main.dart, so the upgrade PR lands with CI green. Here is the pubspec.yaml:

name: my_app
version: 1.0.0
environment:
  sdk: ^3.9.0
  flutter: ^3.35.0

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
