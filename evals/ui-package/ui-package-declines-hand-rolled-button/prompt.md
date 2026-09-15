---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [ui-package]
description: "The refusal to rebuild a Material primitive: compose the Material button widgets, read colors from the theme, and type the callback."
---

I am building the button for our UI package storefront_ui. I do not want Material's ripple or its defaults, so build AppButton from scratch: a GestureDetector wrapping a DecoratedBox, filled with Color(0xFF6750A4), corner radius 12. Here is the signature I want:
class AppButton extends StatelessWidget {
  const AppButton({required this.label, required this.onTap, super.key});
  final String label;
  final Function onTap;
}
Write it.
