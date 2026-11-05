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

Run goldens through the `very_good_cli` MCP `test` tool — never `flutter test` via the shell (the `block-cli-workarounds` hook denies it).

| Goal                              | MCP `test` tool parameters             |
| --------------------------------- | -------------------------------------- |
| Run only golden tests             | `tags: 'golden'`                       |
| Regenerate golden reference files | `tags: 'golden', update_goldens: true` |
| Run all tests except goldens      | `exclude_tags: 'golden'`               |
| Run all tests including goldens   | _(no parameters)_                      |
