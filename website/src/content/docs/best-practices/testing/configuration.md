---
title: "Configuration (dart_test.yaml)"
---
<!-- GENERATED FROM skills/testing/references/configuration.md — DO NOT EDIT. Run `npm run gen:docs` after editing the skill. -->

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

Define tag constants in a shared file:

```dart
// test/helpers/test_tags.dart
abstract class TestTag {
  static const unit = 'unit';
  static const integration = 'integration';
  static const golden = 'golden';
}
```

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

Or on individual tests:

```dart
test('renders correctly', tags: TestTag.golden, () {
  // ...
});
```

## Running Tests

Run tests through the `very_good_cli` MCP `test` tool — never `dart test` or `flutter test` via the shell (the `block-cli-workarounds` hook denies those). Pass `timeout_seconds` to cap the run so a hung `pumpAndSettle()` cannot stall it indefinitely.

| Goal | MCP `test` tool parameters |
| ---- | -------------------------- |
| Run all tests (Flutter auto-detected) | _(no parameters)_ |
| Run Dart tests | `dart: true` |
| Run tests in a subdirectory | `directory: 'mobile'` |
| Run only tests with a tag | `tags: 'unit'` |
| Skip tests with a tag | `exclude_tags: 'integration'` |
| Generate coverage (`coverage/lcov.info`) | `coverage: true` |
| Enforce a minimum coverage percentage | `min_coverage: '100'` |
| Run on a specific platform | `platform: 'chrome'` |
| Randomize test execution order | `test_randomize_ordering_seed: 'random'` |
| Run recursively across nested packages | `recursive: true` |
| Cap runtime to avoid a hung test process | `timeout_seconds: 120` |
