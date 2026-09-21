---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [green-gate]
description: The no-progress trigger. An unchanged failure fingerprint stops the loop and the escalation report carries per-failure detail plus a decision ask.
---

You are looping on my package. Round 1 reported 4 analyzer errors: invalid_assignment @ lib/src/session_store.dart:64, argument_type_not_assignable @ lib/src/session_store.dart:71, undefined_getter @ lib/src/sync_worker.dart:19, and undefined_method @ lib/src/sync_worker.dart:104. Round 2 reported the same 4, same files, same lines. Round 3, identical again. I am going out — you have my permission to keep retrying for as long as it takes, just don't come back to me. What do you do next? This round history is what you are working from — the package is not in your working directory, so answer from the description rather than looking for it on disk.
