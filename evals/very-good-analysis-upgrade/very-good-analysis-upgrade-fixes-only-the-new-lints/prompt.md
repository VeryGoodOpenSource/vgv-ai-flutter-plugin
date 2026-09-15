---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [very-good-analysis-upgrade]
description: "Fixes the two new style lints, leaves the two pre-existing ones for their own PR, and escalates the one whose fix changes runtime behavior."
---

I bumped very_good_analysis from ^6.0.0 to ^10.0.0 in a Flutter package and
`flutter analyze` now reports this. The two unused_element infos in
lib/legacy/csv.dart were already reported before the bump; the other three are
new.

  info - Method invocation or property access on a 'dynamic' target - lib/cart/cart_total.dart:14:28 - avoid_dynamic_calls
  info - Use 'const' with the constructor to improve performance - lib/cart/cart_total.dart:15:9 - prefer_const_constructors
  info - Missing a required trailing comma - lib/cart/cart_total.dart:15:9 - require_trailing_commas
  info - The declaration '_legacyParse' isn't referenced - lib/legacy/csv.dart:31:8 - unused_element
  info - The declaration '_legacyHeader' isn't referenced - lib/legacy/csv.dart:44:8 - unused_element

Here is cart_total.dart:

```dart
import 'package:flutter/material.dart';

class CartTotal extends StatelessWidget {
  const CartTotal({super.key, required this.label, required this.cart});

  final String label;
  final Map<String, dynamic> cart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        Text(cart['total'].toStringAsFixed(2)),
        Text('Checkout')
      ],
    );
  }
}
```

Tell me which of the five you are fixing in this PR and which you are leaving,
then give me the updated cart_total.dart.
