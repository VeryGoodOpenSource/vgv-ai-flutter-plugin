---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [navigation]
description: "The skill's testing guidance: mock GoRouter with mocktail and provide it through InheritedGoRouter instead of building a real router."
---

My app routes with GoRouter. Write a widget test asserting that tapping a ProductCard navigates to the /products/:id route, mocking the router rather than building a real one. Output Dart code only.
