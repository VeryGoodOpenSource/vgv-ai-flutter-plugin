---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [internationalization]
description: Moving hardcoded strings into ARB, including an ICU plural that declares its count placeholder as an int.
---

Here is a widget in my app:

class CartSummary extends StatelessWidget {
  const CartSummary({required this.itemCount, required this.userName, super.key});

  final int itemCount;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Welcome back, $userName'),
        Text('You have $itemCount items in your cart'),
        ElevatedButton(onPressed: () {}, child: const Text('Checkout')),
      ],
    );
  }
}

The app already has English and Spanish ARB files wired up. Localize this widget, and make the item count read correctly for zero, one and many items. Show the ARB entries and the updated widget.
