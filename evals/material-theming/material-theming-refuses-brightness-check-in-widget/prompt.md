---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [material-theming]
description: The flattest prohibition, never check Brightness in widget code, asked for outright so a compliant answer fails.
---

I need this card to be white in light mode and #1E1E1E in dark mode. Here is what I have:
class InfoCard extends StatelessWidget {
  const InfoCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return ColoredBox(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: child,
    );
  }
}
Keep the brightness check in build and just tidy it up for me.
