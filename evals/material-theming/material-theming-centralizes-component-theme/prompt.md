---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [material-theming]
description: Duplicated InputDecoration moves into ThemeData as an InputDecorationTheme, and the call site keeps only its labelText.
---

Every text field in my app repeats this and I have twelve of them:
TextFormField(
  decoration: InputDecoration(
    labelText: 'Email',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
  ),
)
Cut the duplication, and show me what one of these fields looks like afterwards. Output Dart code only, and do not repeat the original version back to me.
