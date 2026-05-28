# Package-Level Testing

## Testing a Data Client

Mock the HTTP client and verify request/response handling.

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_api_client/user_api_client.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  group(UserApiClient, () {
    late http.Client httpClient;
    late UserApiClient subject;

    setUp(() {
      httpClient = _MockHttpClient();
      subject = UserApiClient(
        baseUrl: 'https://api.test.com',
        httpClient: httpClient,
      );
    });

    group('getUser', () {
      test('returns $UserResponse when status is 200', () async {
        when(() => httpClient.get(any())).thenAnswer(
          (_) async => http.Response(
            json.encode({
              'id': '1',
              'email': 'dash@example.com',
              'display_name': 'Dash',
              'avatar_url': null,
            }),
            200,
          ),
        );

        final result = await subject.getUser('1');

        expect(
          result,
          isA<UserResponse>()
              .having((r) => r.id, 'id', '1')
              .having((r) => r.email, 'email', 'dash@example.com')
              .having((r) => r.displayName, 'displayName', 'Dash'),
        );

        verify(
          () => httpClient.get(Uri.parse('https://api.test.com/users/1')),
        ).called(1);
      });

      test('throws $UserApiException when status is not 200', () {
        when(() => httpClient.get(any())).thenAnswer(
          (_) async => http.Response('Not found', 404),
        );

        expect(
          () => subject.getUser('1'),
          throwsA(
            isA<UserApiException>()
                .having((e) => e.statusCode, 'statusCode', 404),
          ),
        );
      });
    });
  });
}
```

## Testing a Repository

Mock the data client and verify domain model transformation.

```dart
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_api_client/user_api_client.dart';
import 'package:user_repository/user_repository.dart';

class _MockUserApiClient extends Mock implements UserApiClient {}

void main() {
  group(UserRepository, () {
    late UserApiClient userApiClient;
    late UserRepository subject;

    setUp(() {
      userApiClient = _MockUserApiClient();
      subject = UserRepository(userApiClient: userApiClient);
    });

    group('getUser', () {
      const userId = '1';
      final userResponse = UserResponse(
        id: userId,
        email: 'dash@example.com',
        displayName: 'Dash',
      );

      test('returns $User when API call succeeds', () async {
        when(() => userApiClient.getUser(userId))
            .thenAnswer((_) async => userResponse);

        final result = await subject.getUser(userId);

        expect(
          result,
          equals(
            const User(
              id: userId,
              email: 'dash@example.com',
              displayName: 'Dash',
            ),
          ),
        );
      });

      test('throws $UserNotFoundException when API returns 404', () {
        when(() => userApiClient.getUser(userId)).thenThrow(
          const UserApiException(404, 'Not found'),
        );

        expect(
          () => subject.getUser(userId),
          throwsA(isA<UserNotFoundException>()),
        );
      });

      test('rethrows $UserApiException for non-404 errors', () {
        when(() => userApiClient.getUser(userId)).thenThrow(
          const UserApiException(500, 'Server error'),
        );

        expect(
          () => subject.getUser(userId),
          throwsA(
            isA<UserApiException>()
                .having((e) => e.statusCode, 'statusCode', 500),
          ),
        );
      });
    });
  });
}
```

## Running Tests Recursively

From the monorepo root, test all packages at once using the `very_good_cli` MCP server tool `test`: `-r --min-coverage 100`. When the Dart/Flutter project is in a subdirectory of the workspace (e.g. `mobile/`), pass `directory: 'mobile'` so the tool runs against the project root.

This recursively finds and runs tests in every package (data clients, repositories, and the root app).

## Key Testing Rules

- **Test each layer in isolation** -- data client tests mock the HTTP client, repository tests mock the data client, Bloc tests mock the repository
- **Mock only the immediate dependency** -- never mock two layers deep (e.g., don't mock the HTTP client when testing a repository)
- **Test model transformations explicitly** -- verify that `User.fromResponse` (or equivalent) correctly maps every field, including nullable fields and edge cases
- **Mirror `lib/` structure in `test/`** -- `packages/user_api_client/lib/src/user_api_client.dart` -> `packages/user_api_client/test/src/user_api_client_test.dart`

## Testing Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
| --- | --- | --- |
| Testing repository with a real HTTP client | Crosses layer boundary -- test becomes slow, flaky, and tests two layers at once | Mock the data client (`_MockUserApiClient`) and test repository logic only |
| Mocking two layers deep | Repository test mocks `http.Client` instead of `UserApiClient` -- tightly couples test to data layer internals | Each test mocks only its direct dependency |
| Skipping model transformation tests | `User.fromResponse` bugs go undetected -- wrong fields mapped, nulls mishandled | Write explicit tests for every factory/transformation method |
| Sharing mutable test state across packages | Global variables or static mocks leak between test files -- causes intermittent failures | Use `late` + `setUp` in every test group for fresh instances |
