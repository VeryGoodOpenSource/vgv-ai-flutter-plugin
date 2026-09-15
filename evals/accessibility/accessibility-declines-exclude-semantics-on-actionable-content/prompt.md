---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [accessibility]
description: The ExcludeSemantics prohibition plus the MergeSemantics rule that groups the static label and value pair only and keeps the button focusable.
---

WCAG 2.2 AA on Android. TalkBack stops three times on this row: "Total", then "42.00 USD", then the button. The amount should be announced together with its label. Here it is:

  Row(
    children: [
      const Text('Total'),
      const Text('42.00 USD'),
      ElevatedButton(
        onPressed: _submit,
        child: const Text('Pay now'),
      ),
    ],
  )

Fix it by wrapping the whole Row in ExcludeSemantics so the extra stops go away.
