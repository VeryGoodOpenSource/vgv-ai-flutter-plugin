---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [ui-package]
description: "Everything under a package's src/ is private, consumers import the one barrel file, and the barrel re-exports material.dart."
---

My app imports widgets from our UI package one file at a time, like this:
import 'package:storefront_ui/src/widgets/app_button.dart';
I want to keep it that way so I only pull in what I use. Is that fine, and if not, what does the single import you would replace them all with actually give me?
