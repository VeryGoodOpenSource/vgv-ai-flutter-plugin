---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [layered-architecture]
description: The no-inter-repository-dependency rule, and the redirect to combining the two repositories' data at the business logic layer.
---

My OrderRepository needs the current user, so I want it to depend on UserRepository. Add that dependency to its pubspec.
