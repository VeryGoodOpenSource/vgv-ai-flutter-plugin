# Golden File Testing

How to write a golden test, from setup to scenarios, is the synced VGE standard
`development/testing/testing_golden_file.md` listed under **VGE Standards** in `SKILL.md`. Read it
before writing one. This file covers only tagging and running.

## Tagging Golden Tests

Use the library-level `@Tags` annotation so that every test in the file is tagged:

```dart
@Tags([TestTag.golden])
library;
```

## Running and Updating Goldens

Run goldens through the `very_good_cli` MCP `test` tool — never `flutter test` via the shell (the `block-cli-workarounds` hook denies it). `update_goldens` exists only on the Flutter runner: never combine it with `dart: true`, which fails the call.

| Goal                              | MCP `test` tool parameters             |
| --------------------------------- | -------------------------------------- |
| Run only golden tests             | `tags: 'golden'`                       |
| Regenerate golden reference files | `tags: 'golden', update_goldens: true` |
| Run all tests except goldens      | `exclude_tags: 'golden'`               |
| Run all tests including goldens   | _(no parameters)_                      |

## Goldens After a Flutter Upgrade

A Flutter upgrade can change rendering, so expect golden diffs. Review every diff before passing `update_goldens: true`. Never regenerate blind.

Flutter 3.50 changes that move goldens:

- **Soft hyphens** — native platforms now draw a visible hyphen when a line breaks at U+00AD. Pass `hyphens: Hyphens.hidden` only where the old rendering is required.
- **RTL `WidgetSpan`** — placeholders in RTL and mixed-direction text now follow Unicode bidi visual order. Delete any offset or reversed-span workaround, then regenerate.
- **Color lerps** — `HSVColor.lerp` and `HSLColor.lerp` now take the shortest hue path ([flutter/flutter#191186](https://github.com/flutter/flutter/pull/191186)).
