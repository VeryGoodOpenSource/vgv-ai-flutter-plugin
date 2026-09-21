---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [layered-architecture]
description: "Bootstrap wiring: clients and repositories constructed in a main entrypoint, passed into App, provided to the tree, and depended on by path rather than by version."
---

My monorepo has two local packages that nothing is wired to yet: `packages/auth_repository`, exposing `AuthRepository`, and `packages/user_repository`, exposing `UserRepository`. They are not in your working directory, so answer from this description rather than inspecting what is on disk. Wire them into the app so every feature can reach them. Show the Dart code and the pubspec changes.
