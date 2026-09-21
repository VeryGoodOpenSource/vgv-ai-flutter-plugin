---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [accessibility]
description: The Phase 1 and Phase 2 gate, where level and platforms are withheld so the skill must ask both before auditing.
---

Can you audit this widget for accessibility before we ship it?

  class PromoCard extends StatelessWidget {
    const PromoCard({required this.onTap, super.key});
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 20,
          child: Row(
            children: [
              Image.asset('assets/promo.png'),
              const Text('50% off today'),
            ],
          ),
        ),
      );
    }
  }
