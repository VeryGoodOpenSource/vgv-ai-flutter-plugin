---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [animations]
description: Motion spread across features gets a centralized AppMotion class whose constants are M3 tokens, then one usage of it.
---

Animations are spreading across a dozen features in our app: page transitions, card fades, a pulsing notification badge. Set up whatever shared piece keeps their timing and easing consistent, then show one card fade using it. Output Dart code only.
