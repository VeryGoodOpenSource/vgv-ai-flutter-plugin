# Coverage

## Achieving Full Coverage

- Test **every public method** --- including edge cases, error paths, and empty inputs
- Test **every branch** --- `if`/`else`, `switch` cases, early returns, ternary operators
- Test **error paths** --- `catch` blocks, `throwsA` assertions, error states
- Test **copyWith** --- verify each field independently to cover every default branch
- Test **Equatable props** --- ensure `==` and `hashCode` behave correctly (instances with same props are equal, different props are not)
- Test **toString** if overridden --- assert the output string matches expectations

## Coverage-Driven Patterns

Testing `copyWith` for full branch coverage:

```dart
group('copyWith', () {
  test('returns same instance when no arguments are provided', () {
    const state = TodoListState(
      status: TodoListStatus.success,
      todos: [Todo(id: '1', title: 'Test')],
    );

    expect(state.copyWith(), equals(state));
  });

  test('returns updated status when status is provided', () {
    const state = TodoListState();

    final result = state.copyWith(status: TodoListStatus.loading);

    expect(result.status, equals(TodoListStatus.loading));
    expect(result.todos, equals(state.todos));
  });

  test('returns updated todos when todos is provided', () {
    const state = TodoListState();
    final todos = [Todo(id: '1', title: 'New')];

    final result = state.copyWith(todos: todos);

    expect(result.todos, equals(todos));
    expect(result.status, equals(state.status));
  });
});
```

## Quick Reference

### Packages

| Package | Purpose | Dev dependency? |
| --- | --- | --- |
| `test` | Core Dart test framework | Yes |
| `flutter_test` | Flutter test framework (includes `test`) | Yes (SDK) |
| `mocktail` | Mock creation and stubbing | Yes |
| `fake_async` | Control async execution (timers, microtasks) | Yes |
| `clock` | Injectable clock for time-dependent logic | No |
| `bloc_test` | Mock Blocs/Cubits for widget tests | Yes |

### Imports

| Import | When to use |
| --- | --- |
| `import 'package:test/test.dart';` | Pure Dart packages (no Flutter dependency) |
| `import 'package:flutter_test/flutter_test.dart';` | Flutter packages (re-exports `package:test`) |
| `import 'package:mocktail/mocktail.dart';` | Any test file that uses `Mock`, `Fake`, `when`, `verify` |
| `import '../helpers/helpers.dart';` | Every widget and golden test file --- provides `pumpApp` and `TestTag` |
