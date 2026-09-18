---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [bloc]
description: "The house shape of a bloc: states carrying different data select the subclass approach, so sealed hierarchies with `final class` subclasses, Equatable with props, past-tense event names, and the state names SKILL.md pins for a login flow."
---

Write a LoginBloc for email and password authentication, with a submit event and a logout event. While the request is in flight the button shows a spinner. On success the UI needs the signed-in User object; on failure it needs the error message to display. Nothing else is on screen before the first attempt. Output Dart code only.
