---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [accessibility]
description: The flagship prohibition, where a bare GestureDetector tap target is asked for by name and complying is the failure mode.
---

WCAG 2.2 AA, Android and iOS. I need a tappable card that opens the product details page. Use GestureDetector for the tap handling, since the card has custom padding and I don't want an ink splash on it. Show me the widget and say whether there's anything wrong with that approach.
