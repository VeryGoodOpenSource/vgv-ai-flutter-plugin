---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [ui-package]
description: "Widget tests pumped through the package's reusable pumpApp helper, which carries the package theme."
---

This widget lives in my UI package storefront_ui at lib/src/widgets/app_counter_button.dart:
class AppCounterButton extends StatelessWidget {
  const AppCounterButton({required this.count, required this.onPressed, super.key});
  final int count;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: Text('$count'));
  }
}
Write its tests. Output Dart code only.
