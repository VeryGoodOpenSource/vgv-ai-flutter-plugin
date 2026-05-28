# Data Flow Walkthrough

Step-by-step code walkthrough: user taps "Load Profile" button.

**Step 1 -- Presentation dispatches event:**

```dart
// lib/profile/view/profile_view.dart
ElevatedButton(
  onPressed: () {
    context.read<ProfileBloc>().add(
      const ProfileLoadRequested(userId: '123'),
    );
  },
  child: const Text('Load Profile'),
)
```

**Step 2 -- Business Logic calls repository:**

```dart
// lib/profile/bloc/profile_bloc.dart
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
```

**Step 3 -- Repository calls data client:**

```dart
// packages/user_repository/lib/src/user_repository.dart
Future<User> getUser(String userId) async {
  final response = await _userApiClient.getUser(userId);
  return User(
    id: response.id,
    email: response.email,
    displayName: response.displayName,
    avatarUrl: response.avatarUrl,
  );
}
```

**Step 4 -- Data layer communicates with external source:**

```dart
// packages/user_api_client/lib/src/user_api_client.dart
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
```

**Step 5 -- Data flows back up -- Presentation rebuilds:**

```dart
// lib/profile/view/profile_view.dart
BlocBuilder<ProfileBloc, ProfileState>(
  builder: (context, state) {
    return switch (state) {
      ProfileInitial() => const SizedBox.shrink(),
      ProfileLoading() => const CircularProgressIndicator(),
      ProfileSuccess(:final user) => ProfileContent(user: user),
      ProfileNotFound() => const Text('User not found'),
      ProfileFailure() => const Text('Something went wrong'),
    };
  },
)
```
