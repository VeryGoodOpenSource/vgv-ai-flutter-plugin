---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [material-theming]
description: A review-this request pulls both the color and the TextStyle out of the widget, and drops EdgeInsets.fromLTRB.
---

Here is a widget from my app. Review it and give me the corrected version. Output Dart code only, and do not repeat the original version back to me.
class PriceTag extends StatelessWidget {
  const PriceTag({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Colors.blue,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
