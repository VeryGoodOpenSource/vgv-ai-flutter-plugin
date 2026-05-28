# Golden File Testing

Golden tests capture a rendered widget as an image and compare it against a stored reference file (the "golden"). They validate visual appearance --- layout, colors, typography, and spacing --- without requiring behavioral assertions.

## When to Use Goldens vs Behavioral Tests

| Concern | Test type | Why |
| --- | --- | --- |
| Button triggers navigation | Widget test | Behavioral outcome |
| Page shows correct text for state | Widget test | Content based on logic |
| Widget matches design spec visually | Golden test | Pixel-level appearance |
| Layout does not regress after refactor | Golden test | Visual regression detection |
| Icon/color changes with theme | Golden test | Visual property |

## Setup and Configuration

1. Declare the `golden` tag in `dart_test.yaml`:

```yaml
tags:
  golden:
```

1. Define a `TestTag` constant (if not already present):

```dart
// test/helpers/test_tags.dart
abstract class TestTag {
  static const golden = 'golden';
}
```

## Writing a Golden Test

```dart
@Tags([TestTag.golden])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/helpers.dart';

void main() {
  group(ProfileCard, () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpApp(
        const ProfileCard(name: 'Dash', role: 'Mascot'),
      );

      await expectLater(
        find.byType(ProfileCard),
        matchesGoldenFile('goldens/profile_card.png'),
      );
    });
  });
}
```

## Tagging Golden Tests

Use the library-level `@Tags` annotation so that every test in the file is tagged:

```dart
@Tags([TestTag.golden])
library;
```

For files that mix golden and behavioral tests, tag individual tests:

```dart
testWidgets('matches golden', tags: TestTag.golden, (tester) async {
  // ...
});
```

## Running and Updating Goldens

| Command | Purpose |
| --- | --- |
| `flutter test --tags golden` | Run only golden tests |
| `flutter test --tags golden --update-goldens` | Regenerate golden reference files |
| `flutter test --exclude-tags golden` | Run all tests except goldens |
| `flutter test` | Run all tests including goldens |

After updating goldens, review and commit the new `.png` files --- they are the source of truth.

## Golden Testing Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
| --- | --- | --- |
| Untagged golden tests | Cannot run or update goldens independently | Always tag with `TestTag.golden` |
| Testing behavior with goldens | Goldens verify appearance, not logic | Use widget tests for behavioral assertions |
| Uncommitted golden files | CI fails because reference images are missing | Commit `.png` goldens alongside test code |
| Raw string tags (`tags: 'golden'`) | Fragile; typos silently create new tags | Use `TestTag.golden` constant |
