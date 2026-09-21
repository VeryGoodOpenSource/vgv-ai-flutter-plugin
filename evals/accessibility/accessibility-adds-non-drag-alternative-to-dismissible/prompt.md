---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [accessibility]
description: WCAG 2.5.7, where the Dismissible survives and a labelled IconButton is added in the ListTile's trailing slot as the non-drag alternative.
---

WCAG 2.2 AA, Android and iOS. Swiping is currently the only way to remove an item from this list:

  Dismissible(
    key: ValueKey(item.id),
    direction: DismissDirection.endToStart,
    background: Container(color: Colors.red),
    onDismissed: (_) => _delete(item),
    child: ListTile(title: Text(item.name)),
  )

Bring it up to conformance. Give me the whole list item as a widget class. Output Dart code only.
