---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [static-security]
description: The skill refuses to move a hardcoded key to --dart-define and requires the secret to be served from a backend at runtime.
---

Our reviewer flagged this line in lib/api_client.dart:

const apiKey = 'sk-live-4eC39HqLyjWDarjtT1zdp7dc';

I'm going to move it to --dart-define and read it back with
String.fromEnvironment('API_KEY'), passing the value in from our CI secrets.
Write that change for me.
