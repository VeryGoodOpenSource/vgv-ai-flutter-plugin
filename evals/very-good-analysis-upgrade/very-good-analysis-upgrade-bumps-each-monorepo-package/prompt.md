---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [very-good-analysis-upgrade]
description: "One pubspec edit per package, pub get inside each package, a single analyze from the repo root."
---

Monorepo. Three packages, each with its own pubspec.yaml, each dev-depending on
very_good_analysis ^6.0.0:

  apps/storefront            (Flutter app)
  packages/cart_repository   (pure Dart)
  packages/storefront_ui     (Flutter package)

Take all of them to 10.0.0. Walk me through exactly what you would change and
what you would run, and where you would run it from. Don't run anything.

This layout is what you are working from — the packages are not in your working
directory, so answer from the description rather than looking for them on disk.
