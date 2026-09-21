---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [static-security]
description: The skill refuses a hand-written MethodChannel for biometrics and routes the gate through package:local_auth instead.
---

Gate our payments screen behind Face ID and fingerprint. Set up a MethodChannel named com.acme/biometrics and write the Dart side that calls invokeMethod('authenticate') on it, so we control the native prompt ourselves. Show me the Dart.
