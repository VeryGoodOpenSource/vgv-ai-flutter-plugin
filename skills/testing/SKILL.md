---
name: vgv-testing
description: Best practices for Dart unit tests, Flutter widget tests, and golden file tests.
when_to_use: Use when writing, modifying, or reviewing tests that use package:test, package:flutter_test, package:mocktail, or package:bloc_test.
argument-hint: "[file-or-directory]"
allowed-tools: Read Glob Grep mcp__very-good-cli__test
---

# Dart & Flutter Testing

Testing fundamentals for Dart and Flutter projects — unit tests, widget tests, and golden file tests — using `package:test`, `package:flutter_test`, `package:mocktail`, and `package:bloc_test`.

## Core Standards

Apply these standards to ALL test work:

- **Descriptive test names** — verbose, readable names that describe the behavior; never `'works'` or `'renders'`
- **Hierarchical group/test structure that reads as natural sentences** — top-level `group` for the class, nested `group` for the method, `test` for the behavior (e.g., `UserRepository` → `getUser` → `returns User when API succeeds`)
- **String interpolation for type references** — use `'returns $User'` not `'returns User'` so renames propagate automatically
- **Private mocks per file** — declare `class _MockX extends Mock implements X {}` with underscore prefix to prevent cross-file coupling
- **Contained test setup within groups** — all `setUp`/`tearDown` calls live inside a `group`, never at the top level of `main()`
- **Initialize mutable objects in `setUp()` with `late`** — declare `late MyDep dep;` then assign in `setUp` so each test gets a fresh instance
- **No shared mutable state between tests** — never use static members, global variables, or top-level final instances that persist across tests
- **Use `package:mocktail`** — never `package:mockito`
- **Constant test tags** — use an `abstract class TestTag` with `static const` fields; never pass raw string literals as tags
- **Test behavior, not properties** — widget tests focus on functional outcomes; static visual properties validated via golden tests
- **Use `pumpApp` test helper** — wrap widgets via shared helper in `test/helpers/pump_app.dart`; never inline `pumpWidget(MaterialApp(...))`
- **Tag all golden tests** — annotate with `TestTag.golden` so goldens can run/update independently

## Test Structure

### File Organization

| Convention | Rule |
| --- | --- |
| **File suffix** | Every test file ends with `_test.dart` |
| **Directory** | All tests live under `test/` |
| **Mirror structure** | `test/` mirrors `lib/` exactly — `lib/src/models/user.dart` → `test/src/models/user_test.dart` |
| **Helpers** | Shared test utilities go in `test/helpers/` (e.g., `pump_app.dart`, `fakes.dart`) |

### Group and Test Hierarchy

Structure groups so that concatenated descriptions read as natural sentences. Use `PascalCase` type references in the top-level group.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_app/user_repository.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  group(UserRepository, () {
    late ApiClient apiClient;
    late UserRepository subject;

    setUp(() {
      apiClient = _MockApiClient();
      subject = UserRepository(apiClient: apiClient);
    });

    group('getUser', () {
      test('returns $User when API call succeeds', () async {
        when(() => apiClient.fetchUser(any()))
            .thenAnswer((_) async => User(id: '1', name: 'Dash'));

        final result = await subject.getUser('1');

        expect(result, equals(User(id: '1', name: 'Dash')));
        verify(() => apiClient.fetchUser('1')).called(1);
      });

      test('throws $UserNotFoundException when API returns 404', () {
        when(() => apiClient.fetchUser(any()))
            .thenThrow(ApiException(statusCode: 404));

        expect(
          () => subject.getUser('1'),
          throwsA(isA<UserNotFoundException>()),
        );
      });
    });

    group('deleteUser', () {
      test('calls apiClient.deleteUser with correct id', () async {
        when(() => apiClient.deleteUser(any()))
            .thenAnswer((_) async {});

        await subject.deleteUser('1');

        verify(() => apiClient.deleteUser('1')).called(1);
      });
    });
  });
}
```

### Naming Conventions

| Pattern | Example |
| --- | --- |
| **Returns a value** | `'returns $User when API call succeeds'` |
| **Throws an exception** | `'throws $UserNotFoundException when user is not found'` |
| **Calls a dependency** | `'calls apiClient.deleteUser with correct id'` |
| **Emits states** | `'emits [loading, success] when data is fetched'` |
| **Conditional behavior** | `'returns cached value when cache is not expired'` |
| **Edge case** | `'returns empty list when repository has no items'` |

## Lifecycle Methods

| Method | Runs | Use for |
| --- | --- | --- |
| `setUp` | Before **each** test | Creating fresh mocks, instantiating the subject under test |
| `tearDown` | After **each** test | Closing streams, resetting singletons, disposing controllers |
| `setUpAll` | Once before **all** tests in the group | Registering fallback values, expensive one-time initialization |
| `tearDownAll` | Once after **all** tests in the group | Releasing shared resources (e.g., database connections) |

### Correct setUp Pattern

Always use `late` + `setUp` inside a group for mutable dependencies:

```dart
group(AuthService, () {
  late AuthRepository authRepository;
  late TokenStorage tokenStorage;
  late AuthService subject;

  setUp(() {
    authRepository = _MockAuthRepository();
    tokenStorage = _MockTokenStorage();
    subject = AuthService(
      authRepository: authRepository,
      tokenStorage: tokenStorage,
    );
  });

  test('authenticates with valid credentials', () async {
    when(() => authRepository.signIn(any(), any()))
        .thenAnswer((_) async => Token('abc'));
    when(() => tokenStorage.save(any()))
        .thenAnswer((_) async {});

    await subject.signIn('user', 'pass');

    verify(() => tokenStorage.save(Token('abc'))).called(1);
  });
});
```

### setUpAll vs setUp

Use `setUpAll` for expensive, immutable setup — most commonly `registerFallbackValue`:

```dart
group(OrderRepository, () {
  late ApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(Order(id: '', items: const []));
    registerFallbackValue(Uri());
  });

  setUp(() {
    apiClient = _MockApiClient();
  });

  // tests...
});
```

`registerFallbackValue` only needs to run once because it registers a type globally for `any()` matchers.

## Mocking with Mocktail

### Creating Mocks

Declare mocks as private classes at the bottom of the test file (or top, before `main`):

```dart
class _MockUserRepository extends Mock implements UserRepository {}

class _MockAnalyticsClient extends Mock implements AnalyticsClient {}

class _FakeUser extends Fake implements User {}
```

Use `Fake` when you need a concrete implementation that throws on unimplemented methods rather than returning null.

### Stubbing Methods

| Method | Use for | Example |
| --- | --- | --- |
| `thenReturn` | Synchronous return values | `when(() => mock.name).thenReturn('Dash');` |
| `thenAnswer` | Async / `Future` / `Stream` returns | `when(() => mock.fetch()).thenAnswer((_) async => data);` |
| `thenThrow` | Throwing exceptions | `when(() => mock.fetch()).thenThrow(Exception('fail'));` |

For streams:

```dart
when(() => mock.updates).thenAnswer((_) => Stream.fromIterable([1, 2, 3]));
```

### Argument Matchers

| Matcher | Purpose | Example |
| --- | --- | --- |
| `any()` | Matches any value (requires `registerFallbackValue` for custom types) | `when(() => mock.fetch(any()))` |
| `any(that: matcher)` | Matches values satisfying a matcher | `when(() => mock.fetch(any(that: isA<String>())))` |
| `captureAny()` | Captures the argument for later inspection | `verify(() => mock.save(captureAny()))` |

Capturing arguments for assertion:

```dart
test('passes the correct user to the repository', () async {
  when(() => repository.save(any())).thenAnswer((_) async {});

  await subject.createUser(name: 'Dash');

  final captured = verify(() => repository.save(captureAny())).captured;
  expect(captured.first, isA<User>().having((u) => u.name, 'name', 'Dash'));
});
```

### Verification

| Method | Purpose |
| --- | --- |
| `verify(() => mock.method()).called(n)` | Assert method was called exactly `n` times |
| `verifyNever(() => mock.method())` | Assert method was never called |
| `verifyNoMoreInteractions(mock)` | Assert no other methods were called on the mock |
| `verifyInOrder([...])` | Assert methods were called in a specific order |

### Registering Fallback Values

Register a fallback value for every custom type used with `any()` or `captureAny()`:

```dart
setUpAll(() {
  registerFallbackValue(User(id: '', name: ''));
  registerFallbackValue(Uri.parse('https://example.com'));
});
```

The fallback value is only used when no stub matches — its specific field values do not matter.

## Test Isolation

### Principles

- Each test must pass when run **individually**, in **any order**, and in **parallel**
- Use `--test-randomize-ordering-seed random` to expose hidden dependencies
- All setup logic belongs inside `group` blocks, never at the `main()` level
- Mocks are private to the file — never import mocks from another test file

### Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
| --- | --- | --- |
| `setUp` at the top level of `main()` | Breaks when test runner merges files for optimization | Move `setUp` inside a `group` |
| `final dep = _MockDep();` (top-level) | Same instance shared across all tests; state leaks | Use `late` + `setUp` inside a group |
| `class MockDep extends Mock` (public) | Other test files can import and depend on it | Use `class _MockDep extends Mock` (private) |
| Static/global mutable variables | State persists across tests | Reset in `setUp` or avoid entirely |
| Tests that must run in a specific order | Fragile, fails with random ordering | Make each test fully self-contained |

## Common Test Patterns

### Testing Async Methods

```dart
test('returns list of users from API', () async {
  when(() => apiClient.fetchUsers())
      .thenAnswer((_) async => [User(id: '1', name: 'Dash')]);

  final result = await subject.getUsers();

  expect(result, hasLength(1));
  expect(result.first.name, equals('Dash'));
});
```

### Testing Streams

```dart
test('emits updated values when data changes', () {
  when(() => repository.watch())
      .thenAnswer((_) => Stream.fromIterable([1, 2, 3]));

  expect(
    subject.valueStream,
    emitsInOrder([1, 2, 3]),
  );
});
```

### Testing Exceptions

```dart
test('throws $FormatException when input is invalid', () {
  expect(
    () => subject.parse('invalid'),
    throwsA(
      isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains('invalid'),
      ),
    ),
  );
});
```

### Testing with Equatable

When the class extends `Equatable`, assert directly with `equals`:

```dart
test('returns expected $User', () async {
  when(() => apiClient.fetchUser('1'))
      .thenAnswer((_) async => User(id: '1', name: 'Dash'));

  final result = await subject.getUser('1');

  expect(result, equals(User(id: '1', name: 'Dash')));
});
```

### Testing Private Logic via Public API

Never test private methods directly. Exercise private logic through the public method that uses it:

```dart
// If _normalizeEmail is private, test it through the public createUser method:
test('normalizes email to lowercase before saving', () async {
  when(() => repository.save(any())).thenAnswer((_) async {});

  await subject.createUser(email: 'Dash@Example.COM');

  final captured = verify(() => repository.save(captureAny())).captured;
  expect(captured.first.email, equals('dash@example.com'));
});
```

### Testing Callbacks

```dart
test('calls onSuccess callback when operation completes', () async {
  var callbackCalled = false;
  when(() => repository.save(any())).thenAnswer((_) async {});

  await subject.save(
    data: 'test',
    onSuccess: () => callbackCalled = true,
  );

  expect(callbackCalled, isTrue);
});
```

## Widget Testing

Widget tests verify that Flutter widgets behave correctly — rendering the right content, responding to user interactions, and navigating as expected. They run in a simulated environment without a real device.

### Standards

| Rule | Details |
| --- | --- |
| **Use `testWidgets`** | Every widget test uses `testWidgets` instead of `test` |
| **Prefer `find.byType`** | Default finder; use `find.text` for user-visible content, `find.byKey` only when type/text is ambiguous |
| **Group by behavior category** | Use `renders`, `navigates`, `calls [MethodName]`, `updates` as nested group names |
| **Focus on behavior** | Assert what the widget *does* (shows text, calls callback, navigates); use golden tests for visual appearance |
| **Mock Blocs and Cubits** | Use `MockBloc`/`MockCubit` from `package:bloc_test`; never provide real Blocs in widget tests |

### pumpApp Helper

Create a shared `pumpApp` helper so every widget test wraps the widget under test consistently:

```dart
// test/helpers/pump_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      MaterialApp(
        home: widget,
      ),
    );
  }
}
```

Export it from a barrel file so every test can import it with one line:

```dart
// test/helpers/helpers.dart
export 'pump_app.dart';
```

Usage in tests:

```dart
import '../helpers/helpers.dart';

void main() {
  group(MyWidget, () {
    testWidgets('renders greeting text', (tester) async {
      await tester.pumpApp(const MyWidget());

      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
```

### Pumping Methods

| Method | When to use |
| --- | --- |
| `pumpWidget(widget)` | Initial render — builds the widget tree for the first time |
| `pump()` | Trigger a single frame rebuild (after `setState`, tap, etc.) |
| `pump(Duration)` | Advance time by a specific duration (animations, debounce) |
| `pumpAndSettle()` | Pump repeatedly until no pending frames — use for animations that must complete |

**Prefer `pump()` over `pumpAndSettle()`** — `pumpAndSettle` can hang when infinite animations (e.g., `CircularProgressIndicator`) are present. Use `pump()` for discrete rebuilds.

### Finders

| Finder | Use case | Example |
| --- | --- | --- |
| `find.byType(T)` | Find widgets by type (default choice) | `find.byType(ElevatedButton)` |
| `find.text('x')` | Find text content visible to users | `find.text('Submit')` |
| `find.byKey(Key)` | Find by explicit key (last resort) | `find.byKey(Key('submit_button'))` |
| `find.byWidget(w)` | Find an exact widget instance | `find.byWidget(myWidget)` |
| `find.descendant(of, matching)` | Scoped search within a subtree | `find.descendant(of: find.byType(AppBar), matching: find.text('Title'))` |

### Interactions

```dart
// Tap
await tester.tap(find.byType(ElevatedButton));
await tester.pump();

// Enter text
await tester.enterText(find.byType(TextField), 'hello@example.com');
await tester.pump();

// Drag / scroll
await tester.drag(find.byType(ListView), const Offset(0, -300));
await tester.pump();

// Long press
await tester.longPress(find.byType(ListTile));
await tester.pump();
```

Always call `pump()` (or `pumpAndSettle()`) after every interaction — widgets do not rebuild until a frame is triggered.

### Widget Testing Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
| --- | --- | --- |
| Inline `MaterialApp` in each test | Duplicated boilerplate; inconsistent setup | Use `pumpApp` helper |
| `find.byKey` as default finder | Couples tests to implementation keys | Prefer `find.byType` or `find.text` |
| Testing padding, colors, or font sizes | Fragile; breaks on design tweaks; not behavioral | Use golden tests for visual validation |
| Missing `pump()` after interaction | Widget tree does not rebuild; assertion sees stale state | Always `pump()` after `tap`, `enterText`, etc. |
| Real Blocs in widget tests | Tests become integration tests; slow, brittle, hard to isolate | Use `MockBloc`/`MockCubit` from `bloc_test` |

## Additional Resources

- [references/widget-tests.md](references/widget-tests.md) — widget test structure and themes/localization testing
- [references/golden-tests.md](references/golden-tests.md) — golden file testing (setup, writing goldens, tagging, running/updating, anti-patterns)
- [references/matchers.md](references/matchers.md) — matchers quick reference
- [references/configuration.md](references/configuration.md) — `dart_test.yaml` configuration (tags, commands, platform overrides)
- [references/coverage.md](references/coverage.md) — coverage patterns and package/imports reference
- [references/animation-testing.md](references/animation-testing.md) — testing implicit/explicit animations, AnimatedSwitcher, page transitions, and injected controllers
