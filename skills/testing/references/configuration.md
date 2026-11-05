# Configuration (dart_test.yaml)

## Full Reference

```yaml
# dart_test.yaml — place at the package root alongside pubspec.yaml

# Tags for categorizing tests
tags:
  unit:
  integration:
  golden:

# Default timeout for all tests
timeout: 2x

# Platforms to run tests on
platforms: [vm]

# Number of concurrent test suites
concurrency: 4

# Per-tag overrides
tag_overrides:
  integration:
    timeout: 4x
  golden:
    timeout: 3x

# File and folder-level overrides
override_platforms:
  chrome:
    settings:
      headless: true
```

## Using Tags

Apply tags to tests using the `@Tags` annotation:

```dart
@Tags([TestTag.integration])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connects to remote service', () async {
    // ...
  });
}
```

## Running Tests

Run tests through the `very_good_cli` MCP `test` tool — never `dart test` or `flutter test` via the shell (the `block-cli-workarounds` hook denies those). `dart: true` runs `very_good dart test` and no `dart` runs `very_good test`. The two accept different options, and an option the runner lacks fails the whole call with `Could not find an option named "--…"`, so the runner-only rows below must never be combined with the other runner.

Set `timeout_seconds` on every run, Dart or Flutter. A `timeout` failure is a hang to find (an unbounded `pumpAndSettle()`, an un-awaited stream), not a run to retry.

| Goal                                     | MCP `test` tool parameters               |
| ---------------------------------------- | ---------------------------------------- |
| Run all tests (Flutter auto-detected)    | _(no parameters)_                        |
| Run Dart tests                           | `dart: true`                             |
| Run tests in a subdirectory              | `directory: 'mobile'`                    |
| Run only tests with a tag                | `tags: 'unit'`                           |
| Skip tests with a tag                    | `exclude_tags: 'integration'`            |
| Generate coverage (`coverage/lcov.info`) | `coverage: true`                         |
| Enforce a minimum coverage percentage    | `min_coverage: '100'`                    |
| Run on a specific platform               | `platform: 'chrome'`                     |
| Randomize test execution order           | `test_randomize_ordering_seed: 'random'` |
| Run recursively across nested packages   | `recursive: true`                        |
| Honor `// coverage:ignore` (Dart only)   | `dart: true, check_ignore: true`         |
| Kill a run that hangs past 120 s         | `timeout_seconds: 120`                   |
