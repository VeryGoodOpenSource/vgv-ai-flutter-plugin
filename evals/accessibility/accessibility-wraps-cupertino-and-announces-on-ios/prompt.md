---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [accessibility]
description: iOS remediation on two skill facts, the Cupertino semantics wrapper and the liveRegion gotcha that also needs SemanticsService.announce.
---

iOS-only app, WCAG 2.2 AA. This tile has a sync toggle plus a status line that updates when the upload finishes:

  class SyncTile extends StatelessWidget {
    const SyncTile({
      required this.enabled,
      required this.onChanged,
      required this.status,
      super.key,
    });

    final bool enabled;
    final ValueChanged<bool> onChanged;
    final String status;

    @override
    Widget build(BuildContext context) {
      return Row(
        children: [
          const Text('Sync photos'),
          CupertinoSwitch(value: enabled, onChanged: onChanged),
          Text(status),
        ],
      );
    }
  }

Make it work properly with VoiceOver. Show the updated code and call out anything iOS-specific.
