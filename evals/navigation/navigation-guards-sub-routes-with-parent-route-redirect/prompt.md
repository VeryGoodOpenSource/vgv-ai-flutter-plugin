---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [navigation]
description: "The synced VGE redirect standard: an authorization guard for a section is a route-level redirect on the parent GoRouteData, which runs before its sub-routes, not path matching in the router's global redirect."
---

My app routes with GoRouter. Only premium users may open /premium and its two sub-pages, /premium/shows and /premium/merch. Everyone else should land on /restricted instead. I can read the user's status with `context.read<AppBloc>().state.user.status`, which is a `UserStatus` enum with `free` and `premium` values. Write the routes and the guard. Output Dart code only.
