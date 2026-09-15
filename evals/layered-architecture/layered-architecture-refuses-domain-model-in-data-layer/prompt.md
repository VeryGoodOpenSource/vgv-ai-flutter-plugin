---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [layered-architecture]
description: The prohibition on domain models in the data layer, and whether the refusal comes with the response-model / domain-model split.
---

Put my User domain model inside the user_api_client package so both the repository and the app can import it from one place.
