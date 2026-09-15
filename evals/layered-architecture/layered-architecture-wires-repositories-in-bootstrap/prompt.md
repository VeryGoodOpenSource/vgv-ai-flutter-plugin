---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [layered-architecture]
description: "Bootstrap wiring: clients and repositories constructed in a main entrypoint, passed into App, provided to the tree, and depended on by path rather than by version."
---

Wire my AuthRepository and UserRepository into the app so every feature can reach them. Show the Dart code and the pubspec changes.
