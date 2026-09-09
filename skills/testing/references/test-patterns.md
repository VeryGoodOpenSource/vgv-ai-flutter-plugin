# Lifecycle and Common Test Patterns

## Lifecycle Methods

| Method        | Runs                                   | Use for                                                        |
| ------------- | -------------------------------------- | -------------------------------------------------------------- |
| `setUp`       | Before **each** test                   | Creating fresh mocks, instantiating the subject under test     |
| `tearDown`    | After **each** test                    | Closing streams, resetting singletons, disposing controllers   |
| `setUpAll`    | Once before **all** tests in the group | Registering fallback values, expensive one-time initialization |
| `tearDownAll` | Once after **all** tests in the group  | Releasing shared resources (e.g., database connections)        |

All of them live inside a `group`, never at the top level of `main()`.

## Testing Async Methods

```dart
test('returns list of users from API', () async {
  when(() => apiClient.fetchUsers())
      .thenAnswer((_) async => [User(id: '1', name: 'Dash')]);

  final result = await subject.getUsers();

  expect(result, hasLength(1));
  expect(result.first.name, equals('Dash'));
});
```

## Testing Streams

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

## Testing Exceptions

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

## Testing with Equatable

When the class extends `Equatable`, assert directly with `equals`:

```dart
test('returns expected $User', () async {
  when(() => apiClient.fetchUser('1'))
      .thenAnswer((_) async => User(id: '1', name: 'Dash'));

  final result = await subject.getUser('1');

  expect(result, equals(User(id: '1', name: 'Dash')));
});
```

## Testing Callbacks

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
