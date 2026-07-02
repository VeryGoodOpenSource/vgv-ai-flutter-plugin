---
title: "Green Gate"
description: "Drives a Dart or Flutter package to a fully green state through an autonomous verify-fix-rerun loop across four quality gates — analyze, format, test, and coverage. Exits only when a single final iteration proves all four pass with observed numbers."
---
<!-- GENERATED FROM skills/green-gate/SKILL.md — DO NOT EDIT. Run `npm run gen:docs` after editing the skill. -->

Drives a Dart or Flutter package to a fully green state through an autonomous verify-fix-rerun loop across four quality gates — analyze, format, test, and coverage. Exits only when a single final iteration proves all four pass with observed numbers.

## When to use it

Use when the user wants a Dart or Flutter package driven to a fully passing state, or says things like "green gate", "make it green", "get this package passing", "get CI green", "fix all the analyze and test failures", "clean this package up before I open a PR", "bring coverage to 100", or "loop until everything passes". Prefer this over the single-gate testing or analysis skills when the request spans multiple gates or asks to fix and re-verify until clean.

## How to run it

Invoke the `/green-gate` skill in Claude Code (arguments: `[directory]`).

[View the full skill definition on GitHub](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/blob/main/skills/green-gate/SKILL.md)
