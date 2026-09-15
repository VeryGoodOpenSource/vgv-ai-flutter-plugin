---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [bloc]
description: "The prohibition: the user asks for bloc-to-bloc injection outright, and the skill has to refuse and name a concrete alternative, either passing the value through the UI or sharing a repository."
---

My CartBloc needs the current user id, which lives in AuthBloc's state. Show me how to inject AuthBloc into CartBloc so it can read that state directly.
