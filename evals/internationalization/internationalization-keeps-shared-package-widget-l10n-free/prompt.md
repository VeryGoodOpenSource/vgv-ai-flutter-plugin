---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [internationalization]
description: The prohibition on coupling a shared widget package to AppLocalizations, and the parameter-passing alternative it replaces it with.
---

My design system lives in a separate package called app_ui. Here is a button from it:

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: const Text('Continue'));
  }
}

Give it a localized label. Add AppLocalizations to app_ui and read the string with AppLocalizations.of(context) inside build, so every app using the button gets the translation for free.
