---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [internationalization]
description: "RTL remediation: directional padding, an explicitly mirrored image, and no hand-rolled mirroring of an icon that mirrors itself."
---

We are shipping this app in Arabic. Here is a tile from it:

class MessageTile extends StatelessWidget {
  const MessageTile({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        children: [
          const Icon(Icons.arrow_forward),
          Text(label),
          const Image(image: AssetImage('assets/swipe_hint.png')),
        ],
      ),
    );
  }
}

Make it lay out correctly in Arabic. Output Dart code only, and do not repeat the original version back to me.
