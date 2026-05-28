# Complete Worked Example

End-to-end "user profile" feature across all four layers.

## Data Layer: `user_api_client` Package

**`packages/user_api_client/pubspec.yaml`**

```yaml
name: user_api_client
description: HTTP client for the User API.
version: 0.1.0+1
publish_to: none

environment:
  sdk: ^3.11.0

dependencies:
  http: ^1.4.0
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.9.0
  mocktail: ^1.0.0
  test: ^1.25.0
  very_good_analysis: ^7.0.0
```

**`packages/user_api_client/lib/user_api_client.dart`**

```dart
/// HTTP client for the User API.
library;

export 'src/models/models.dart';
export 'src/user_api_client.dart';
```

**`packages/user_api_client/lib/src/models/models.dart`**

```dart
export 'user_response.dart';
```

**`packages/user_api_client/lib/src/models/user_response.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user_response.g.dart';

@JsonSerializable()
class UserResponse {
  const UserResponse({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);

  final String id;
  final String email;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  Map<String, dynamic> toJson() => _$UserResponseToJson(this);
}
```

**`packages/user_api_client/lib/src/user_api_client.dart`**

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:user_api_client/user_api_client.dart';

/// Exception thrown when a user API request fails.
class UserApiException implements Exception {
  const UserApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;
}

/// HTTP client for the User API.
class UserApiClient {
  UserApiClient({
    required String baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

  /// Fetches the user with the given [userId].
  Future<UserResponse> getUser(String userId) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/users/$userId'),
    );

    if (response.statusCode != 200) {
      throw UserApiException(response.statusCode, response.body);
    }

    return UserResponse.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }
}
```

## Data Layer: `local_storage_client` Package

**`packages/local_storage_client/pubspec.yaml`**

```yaml
name: local_storage_client
description: Client for local key-value storage.
version: 0.1.0+1
publish_to: none

environment:
  sdk: ^3.11.0

dependencies:
  shared_preferences: ^2.5.0

dev_dependencies:
  mocktail: ^1.0.0
  test: ^1.25.0
  very_good_analysis: ^7.0.0
```

**`packages/local_storage_client/lib/local_storage_client.dart`**

```dart
/// Client for local key-value storage.
library;

export 'src/local_storage_client.dart';
```

**`packages/local_storage_client/lib/src/local_storage_client.dart`**

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Client for local key-value storage.
class LocalStorageClient {
  LocalStorageClient({
    required SharedPreferences sharedPreferences,
  }) : _sharedPreferences = sharedPreferences;

  final SharedPreferences _sharedPreferences;

  /// Reads the string value for the given [key].
  String? read(String key) => _sharedPreferences.getString(key);

  /// Writes a string [value] for the given [key].
  Future<void> write(String key, String value) async {
    await _sharedPreferences.setString(key, value);
  }

  /// Removes the value for the given [key].
  Future<void> delete(String key) async {
    await _sharedPreferences.remove(key);
  }
}
```

## Repository Layer: `user_repository` Package

**`packages/user_repository/pubspec.yaml`**

```yaml
name: user_repository
description: Repository for user data.
version: 0.1.0+1
publish_to: none

environment:
  sdk: ^3.11.0

dependencies:
  equatable: ^2.0.7
  local_storage_client:
    path: ../local_storage_client
  user_api_client:
    path: ../user_api_client

dev_dependencies:
  mocktail: ^1.0.0
  test: ^1.25.0
  very_good_analysis: ^7.0.0
```

**`packages/user_repository/lib/user_repository.dart`**

```dart
/// Repository for user data.
library;

export 'src/models/models.dart';
export 'src/user_repository.dart';
```

**`packages/user_repository/lib/src/models/models.dart`**

```dart
export 'user.dart';
```

**`packages/user_repository/lib/src/models/user.dart`**

```dart
import 'package:equatable/equatable.dart';

/// Domain model representing a user.
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, email, displayName, avatarUrl];
}
```

**`packages/user_repository/lib/src/user_repository.dart`**

```dart
import 'package:user_api_client/user_api_client.dart';
import 'package:user_repository/user_repository.dart';

/// Exception thrown when a user is not found.
class UserNotFoundException implements Exception {
  const UserNotFoundException(this.userId);

  final String userId;
}

/// Repository for user data.
///
/// Combines [UserApiClient] with local caching to provide
/// user data to the business logic layer.
class UserRepository {
  const UserRepository({
    required UserApiClient userApiClient,
  }) : _userApiClient = userApiClient;

  final UserApiClient _userApiClient;

  /// Returns the [User] with the given [userId].
  ///
  /// Throws [UserNotFoundException] if the user is not found.
  Future<User> getUser(String userId) async {
    try {
      final response = await _userApiClient.getUser(userId);
      return User(
        id: response.id,
        email: response.email,
        displayName: response.displayName,
        avatarUrl: response.avatarUrl,
      );
    } on UserApiException catch (e) {
      if (e.statusCode == 404) {
        throw UserNotFoundException(userId);
      }
      rethrow;
    }
  }
}
```

## Business Logic Layer: `ProfileBloc`

**`lib/profile/bloc/profile_event.dart`**

```dart
part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

final class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested({required this.userId});

  final String userId;

  @override
  List<Object> get props => [userId];
}
```

**`lib/profile/bloc/profile_state.dart`**

```dart
part of 'profile_bloc.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileSuccess extends ProfileState {
  const ProfileSuccess({required this.user});

  final User user;

  @override
  List<Object?> get props => [user];
}

final class ProfileNotFound extends ProfileState {
  const ProfileNotFound();
}

final class ProfileFailure extends ProfileState {
  const ProfileFailure();
}
```

**`lib/profile/bloc/profile_bloc.dart`**

```dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required UserRepository userRepository,
  })  : _userRepository = userRepository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
  }

  final UserRepository _userRepository;

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final user = await _userRepository.getUser(event.userId);
      emit(ProfileSuccess(user: user));
    } on UserNotFoundException {
      emit(const ProfileNotFound());
    } catch (_) {
      emit(const ProfileFailure());
    }
  }
}
```

## Presentation Layer: Page and View

**`lib/profile/view/profile_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/profile/bloc/profile_bloc.dart';
import 'package:my_app/profile/view/profile_view.dart';
import 'package:user_repository/user_repository.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(
        userRepository: context.read<UserRepository>(),
      )..add(ProfileLoadRequested(userId: userId)),
      child: const ProfileView(),
    );
  }
}
```

**`lib/profile/view/profile_view.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/profile/bloc/profile_bloc.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return switch (state) {
            ProfileInitial() => const SizedBox.shrink(),
            ProfileLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ProfileSuccess(:final user) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(user.email),
                  ],
                ),
              ),
            ProfileNotFound() => const Center(
                child: Text('User not found'),
              ),
            ProfileFailure() => const Center(
                child: Text('Something went wrong'),
              ),
          };
        },
      ),
    );
  }
}
```

## Bootstrap Wiring

**`lib/main_development.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:user_api_client/user_api_client.dart';
import 'package:user_repository/user_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'https://api.dev.example.com';

  final userApiClient = UserApiClient(baseUrl: baseUrl);
  final userRepository = UserRepository(userApiClient: userApiClient);

  runApp(
    App(userRepository: userRepository),
  );
}
```

**`lib/app/view/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';

class App extends StatelessWidget {
  const App({
    required this.userRepository,
    super.key,
  });

  final UserRepository userRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: userRepository,
      child: const MaterialApp(
        home: HomePage(),
      ),
    );
  }
}
```
