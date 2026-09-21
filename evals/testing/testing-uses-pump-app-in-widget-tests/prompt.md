---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [testing]
description: "Widget tests wrap through the shared `pumpApp` helper and drive the view with a MockBloc or MockCubit rather than a real bloc."
---

Write a widget test for a LoginView that shows an error SnackBar when the bloc emits LoginFailure, using our existing widget-test helpers. Output Dart code only.
