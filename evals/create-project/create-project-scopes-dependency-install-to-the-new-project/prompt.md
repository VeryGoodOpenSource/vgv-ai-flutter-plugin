---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [create-project]
description: The create-then-install order, with the install scoped to the created project via directory, plus the organization prompt.
---

I want to scaffold a new Flutter app named storefront, placed at apps/storefront inside my existing monorepo, and then install its dependencies. Which tools would you call, in order, and what arguments would you pass to each? Tell me anything you still need from me. Do not run anything yet.
