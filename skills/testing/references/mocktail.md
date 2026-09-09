# Mocking with Mocktail

VGV uses `package:mocktail`, never `package:mockito`. Mocktail needs no code generation
and no `build_runner` step.

## Creating Mocks

Declare mocks as **private** classes in the test file that uses them, so no other test
file can import and depend on them:

```dart
class _MockUserRepository extends Mock implements UserRepository {}

class _MockAnalyticsClient extends Mock implements AnalyticsClient {}

class _FakeUser extends Fake implements User {}
```

Use `Fake` when you need a concrete implementation that throws on unimplemented methods
rather than returning null.

## Stubbing Methods

| Method       | Use for                             | Example                                                   |
| ------------ | ----------------------------------- | --------------------------------------------------------- |
| `thenReturn` | Synchronous return values           | `when(() => mock.name).thenReturn('Dash');`               |
| `thenAnswer` | Async / `Future` / `Stream` returns | `when(() => mock.fetch()).thenAnswer((_) async => data);` |
| `thenThrow`  | Throwing exceptions                 | `when(() => mock.fetch()).thenThrow(Exception('fail'));`  |

For streams:

```dart
when(() => mock.updates).thenAnswer((_) => Stream.fromIterable([1, 2, 3]));
```

## Argument Matchers

| Matcher              | Purpose                                                               | Example                                            |
| -------------------- | --------------------------------------------------------------------- | -------------------------------------------------- |
| `any()`              | Matches any value (requires `registerFallbackValue` for custom types) | `when(() => mock.fetch(any()))`                    |
| `any(that: matcher)` | Matches values satisfying a matcher                                   | `when(() => mock.fetch(any(that: isA<String>())))` |
| `captureAny()`       | Captures the argument for later inspection                            | `verify(() => mock.save(captureAny()))`            |

Capturing arguments for assertion:

```dart
test('passes the correct user to the repository', () async {
  when(() => repository.save(any())).thenAnswer((_) async {});

  await subject.createUser(name: 'Dash');

  final captured = verify(() => repository.save(captureAny())).captured;
  expect(captured.first, isA<User>().having((u) => u.name, 'name', 'Dash'));
});
```

## Verification

| Method                                  | Purpose                                         |
| --------------------------------------- | ----------------------------------------------- |
| `verify(() => mock.method()).called(n)` | Assert method was called exactly `n` times      |
| `verifyNever(() => mock.method())`      | Assert method was never called                  |
| `verifyNoMoreInteractions(mock)`        | Assert no other methods were called on the mock |
| `verifyInOrder([...])`                  | Assert methods were called in a specific order  |

## Registering Fallback Values

Register a fallback value for every custom type used with `any()` or `captureAny()`.
This belongs in `setUpAll` — it registers a type globally, so it only needs to run once:

```dart
group(OrderRepository, () {
  late ApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(Order(id: '', items: const []));
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    apiClient = _MockApiClient();
  });

  // tests...
});
```

The fallback value is only used when no stub matches — its specific field values do not
matter.
