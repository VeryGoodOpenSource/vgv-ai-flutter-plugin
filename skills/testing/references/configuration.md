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

## Common Commands

| Command | Purpose |
| --- | --- |
| `dart test` | Run all Dart tests |
| `flutter test` | Run all Flutter tests |
| `dart test test/src/models/user_test.dart` | Run a specific test file |
| `dart test --name "returns"` | Filter tests by description substring |
| `dart test --tags unit` | Run only tests with the `unit` tag |
| `dart test --exclude-tags integration` | Skip integration-tagged tests |
| `flutter test --coverage` | Generate `coverage/lcov.info` |
| `dart test --test-randomize-ordering-seed random` | Randomize test execution order |
| `dart test --reporter expanded` | Verbose test output |
