---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [layered-architecture]
description: "Repository-layer code: the data client injected through the constructor, the API response transformed into an Equatable domain model, and both files placed in the repository package, which reaches the data package through its barrel export."
---

Write the WeatherRepository that sits on top of WeatherApiClient, which is a data layer package in my monorepo. The API returns temperature in Fahrenheit and a nested location object. Output Dart code only, with a comment at the top of each file giving the path it belongs at.
