---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [accessibility]
description: With level and platforms supplied, the audit report carries a WCAG ID and name, a CRITICAL/MAJOR/MINOR severity, and a before/after fix per finding.
---

We're targeting WCAG 2.2 level AA on iOS and Android. Audit this screen and report every finding.

  class OrderSummary extends StatelessWidget {
    const OrderSummary({required this.onClose, super.key});
    final VoidCallback onClose;

    @override
    Widget build(BuildContext context) {
      return Column(
        children: [
          Row(
            children: [
              Image.asset('assets/receipt.png'),
              const Spacer(),
              SizedBox(
                width: 16,
                height: 16,
                child: GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
            child: Text('Delivery estimate: 3 to 5 business days'),
          ),
        ],
      );
    }
  }
