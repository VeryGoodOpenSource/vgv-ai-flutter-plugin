# Model Transformation Patterns

## Data Model vs Domain Model

Data models (response models) reflect the external API shape. Domain models reflect the app's internal representation. The repository layer transforms between them.

```text
API JSON -> UserResponse (data model) -> User (domain model)
```

## Factory Constructor Pattern

Add a named factory on the domain model to transform from the response model:

```dart
import 'package:equatable/equatable.dart';
import 'package:user_api_client/user_api_client.dart' show UserResponse;

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  /// Creates a [User] from a [UserResponse].
  factory User.fromResponse(UserResponse response) {
    return User(
      id: response.id,
      email: response.email,
      displayName: response.displayName,
      avatarUrl: response.avatarUrl,
    );
  }

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, email, displayName, avatarUrl];
}
```

Usage in the repository:

```dart
Future<User> getUser(String userId) async {
  final response = await _userApiClient.getUser(userId);
  return User.fromResponse(response);
}
```

## Handling Nullable Fields

When the API returns fields that are optional or may change shape:

```dart
factory User.fromResponse(UserResponse response) {
  return User(
    id: response.id,
    email: response.email,
    // Default when the API field is missing
    displayName: response.displayName ?? 'Unknown',
    // Nullable fields pass through
    avatarUrl: response.avatarUrl,
  );
}
```

## Combining Multiple Data Sources

When a domain model requires data from more than one client:

```dart
class UserRepository {
  const UserRepository({
    required UserApiClient userApiClient,
    required LocalStorageClient localStorageClient,
  })  : _userApiClient = userApiClient,
        _localStorageClient = localStorageClient;

  final UserApiClient _userApiClient;
  final LocalStorageClient _localStorageClient;

  Future<User> getUser(String userId) async {
    final response = await _userApiClient.getUser(userId);
    final cachedNickname = _localStorageClient.read('nickname_$userId');

    return User(
      id: response.id,
      email: response.email,
      displayName: cachedNickname ?? response.displayName,
      avatarUrl: response.avatarUrl,
    );
  }
}
```

## Testing Model Transformations

```dart
group('User.fromResponse', () {
  test('transforms $UserResponse to $User', () {
    const response = UserResponse(
      id: '1',
      email: 'dash@example.com',
      displayName: 'Dash',
      avatarUrl: 'https://example.com/avatar.png',
    );

    expect(
      User.fromResponse(response),
      equals(
        const User(
          id: '1',
          email: 'dash@example.com',
          displayName: 'Dash',
          avatarUrl: 'https://example.com/avatar.png',
        ),
      ),
    );
  });

  test('handles null avatarUrl', () {
    const response = UserResponse(
      id: '1',
      email: 'dash@example.com',
      displayName: 'Dash',
    );

    expect(User.fromResponse(response).avatarUrl, isNull);
  });
});
```
