---
title: "Dart & Flutter SDK Upgrade"
description: "VGV-specific reference for bumping Dart and Flutter SDK constraints across packages. Covers pubspec.yaml environment constraints, CI workflow Flutter versions, and SDK upgrade PR preparation. CI uses ^MAJOR.MINOR.x to resolve to the latest patch; pubspec pins the exact patch version (e.g., ^3.50.1)."
---
<!-- GENERATED FROM skills/dart-flutter-sdk-upgrade/SKILL.md — DO NOT EDIT. Run `npm run gen:docs` after editing the skill. -->

VGV-specific reference for bumping Dart and Flutter SDK constraints across packages. Covers pubspec.yaml environment constraints, CI workflow Flutter versions, and SDK upgrade PR preparation. CI uses ^MAJOR.MINOR.x to resolve to the latest patch; pubspec pins the exact patch version (e.g., ^3.50.1).

## When to use it

Use when upgrading the Flutter or Dart SDK version in any VGV repository. Trigger on phrases like "bump Flutter to 3.x", "update SDK constraints", "upgrade Dart SDK", "update CI Flutter version", "bump SDK version", or "prep the SDK upgrade PR".

## How to run it

Invoke the `/dart-flutter-sdk-upgrade` skill in Claude Code (arguments: `[flutter-version]`).

[View the full skill definition on GitHub](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/blob/main/skills/dart-flutter-sdk-upgrade/SKILL.md)
