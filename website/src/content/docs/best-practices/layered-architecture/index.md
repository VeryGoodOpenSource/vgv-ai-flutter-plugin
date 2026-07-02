---
title: "Layered Architecture"
description: "Best practices for VGV layered monorepo architecture in Flutter."
---
<!-- GENERATED FROM skills/layered-architecture/SKILL.md — DO NOT EDIT. Run `npm run gen:docs` after editing the skill. -->

Layered monorepo architecture for Flutter apps — four layers organized as independent Dart packages with strict unidirectional dependencies.

---

## Core Standards

Apply these standards to ALL layered architecture work:

- **Four layers** — Data, Repository, Business Logic, Presentation — every feature spans exactly these four layers
- **Unidirectional dependencies** — Presentation → Business Logic → Repository → Data — never skip or invert a layer
- **Data and Repository layers live in `packages/`** — each is an independent Dart package with its own `pubspec.yaml`
- **Business Logic and Presentation live in `lib/`** — organized by feature within the app
- **Data layer packages contain zero domain/business logic** — they must be reusable in unrelated projects
- **No inter-repository dependencies** — repositories never import other repositories
- **No Flutter SDK in data or repository packages** — scaffold with the `very_good_cli` MCP server `create dart_package` tool
- **One repository per domain** — `user_repository`, `weather_repository`, `auth_repository`
- **Path dependencies for local packages** — never `git:` or pub version references for packages in the same repo
- **Barrel exports at every package boundary** — `src/` is never imported directly by consumers
- **Repositories accept data layer dependencies via constructor injection** — never instantiate clients internally
- **App bootstrap wires all layers** — `main_<flavor>.dart` creates clients and repositories, provides them via `RepositoryProvider`

## Architecture Overview

| Layer | Responsibility | Location | Depends On | Example |
| --- | --- | --- | --- | --- |
| **Data** | External communication — API calls, local storage, platform plugins | `packages/<name>_api_client/` | External packages only | `user_api_client`, `local_storage_client` |
| **Repository** | Data orchestration — combines data sources, transforms models, caches | `packages/<name>_repository/` | Data layer packages | `user_repository`, `weather_repository` |
| **Business Logic** | State management — processes user actions, emits state changes | `lib/<feature>/bloc/` or `lib/<feature>/cubit/` | Repository layer | `LoginBloc`, `ProfileCubit` |
| **Presentation** | UI — widgets, pages, views, layout | `lib/<feature>/view/` | Business Logic layer | `LoginPage`, `ProfileView` |

```text
┌─────────────────────────────────────────────┐
│              Presentation                   │
│          (lib/<feature>/view/)              │
└──────────────────┬──────────────────────────┘
                   │ reads state / dispatches events
┌──────────────────▼──────────────────────────┐
│            Business Logic                   │
│        (lib/<feature>/bloc/)                │
└──────────────────┬──────────────────────────┘
                   │ calls repository methods
┌──────────────────▼──────────────────────────┐
│              Repository                     │
│      (packages/<name>_repository/)          │
└──────────────────┬──────────────────────────┘
                   │ calls data clients
┌──────────────────▼──────────────────────────┐
│               Data                          │
│     (packages/<name>_api_client/)           │
└─────────────────────────────────────────────┘
```

## Monorepo Structure

```text
my_app/
├── lib/
│   ├── app/
│   │   ├── app.dart                          # Barrel file
│   │   └── view/
│   │       └── app.dart                      # App widget with MultiRepositoryProvider
│   ├── login/                                # Feature: login
│   │   ├── login.dart                        # Barrel file
│   │   ├── bloc/
│   │   │   ├── login_bloc.dart
│   │   │   ├── login_event.dart
│   │   │   └── login_state.dart
│   │   └── view/
│   │       ├── login_page.dart               # Page provides Bloc
│   │       └── login_view.dart               # View consumes state
│   ├── profile/                              # Feature: profile
│   │   ├── profile.dart
│   │   ├── cubit/
│   │   │   ├── profile_cubit.dart
│   │   │   └── profile_state.dart
│   │   └── view/
│   │       ├── profile_page.dart
│   │       └── profile_view.dart
│   ├── main_development.dart                 # Flavor entrypoint
│   ├── main_staging.dart
│   └── main_production.dart
├── packages/
│   ├── auth_api_client/                      # Data layer: auth API
│   │   ├── lib/
│   │   │   ├── auth_api_client.dart          # Barrel file
│   │   │   └── src/
│   │   │       ├── auth_api_client.dart
│   │   │       └── models/
│   │   │           ├── models.dart
│   │   │           └── auth_response.dart
│   │   └── pubspec.yaml
│   ├── local_storage_client/                 # Data layer: local storage
│   │   ├── lib/
│   │   │   ├── local_storage_client.dart
│   │   │   └── src/
│   │   │       └── local_storage_client.dart
│   │   └── pubspec.yaml
│   ├── auth_repository/                      # Repository layer: auth
│   │   ├── lib/
│   │   │   ├── auth_repository.dart          # Barrel file
│   │   │   └── src/
│   │   │       ├── auth_repository.dart
│   │   │       └── models/
│   │   │           ├── models.dart
│   │   │           └── user.dart             # Domain model
│   │   └── pubspec.yaml
│   └── user_repository/                      # Repository layer: user
│       ├── lib/
│       │   ├── user_repository.dart
│       │   └── src/
│       │       ├── user_repository.dart
│       │       └── models/
│       │           ├── models.dart
│       │           └── user_profile.dart
│       └── pubspec.yaml
├── test/
│   └── ...                                   # Mirrors lib/ structure
└── pubspec.yaml                              # Root app pubspec
```

## Data Layer

The data layer handles all external communication. Each data package wraps a single external source (REST API, local database, platform plugin) and exposes typed methods and response models.

**Rules:**
- Models represent the external data shape — match the API/storage schema exactly
- No Flutter imports — use the `very_good_cli` MCP server `create dart_package` tool
- Constructor-inject HTTP clients for testability
- Response models use `fromJson` / `toJson` factories
- Export everything through a barrel file — never expose `src/`

### Pattern: Data Client Class

Constructor-inject the HTTP client for testability. Return typed response models — never raw JSON.

```dart
/// HTTP client for the User API.
class UserApiClient {
  // http.Client injected — tests pass a mock, production gets a real client
  UserApiClient({
    required String baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

  /// Every method returns a typed response model.
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

See [Complete Worked Example](/best-practices/layered-architecture/worked-example) for the complete `user_api_client` package with pubspec, barrel files, response models, and exception class.

## Repository Layer

The repository layer orchestrates data sources and exposes domain models. Each repository composes one or more data clients, transforms response models into domain models, and provides a clean API for the business logic layer.

**Rules:**
- No inter-repository dependencies — repositories are isolated
- No Flutter SDK — the `very_good_cli` MCP server `create dart_package` tool
- Domain models live in the repository package — not in data packages
- Transform data models into domain models — never leak API response shapes upstream
- Accept all data clients via constructor injection

### Pattern: Domain Model + Repository Transformation

Domain models extend `Equatable` and represent the app's internal data shape — distinct from the API response shape. The repository method transforms between them.

```dart
/// Domain model — lives in the repository package, NOT the data package.
/// Fields match the app's needs, not the API schema.
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

```dart
/// Repository accepts data client via constructor — never creates its own.
class UserRepository {
  const UserRepository({
    required UserApiClient userApiClient,
  }) : _userApiClient = userApiClient;

  final UserApiClient _userApiClient;

  /// Transforms UserResponse (API shape) → User (domain shape).
  Future<User> getUser(String userId) async {
    final response = await _userApiClient.getUser(userId);
    return User(
      id: response.id,
      email: response.email,
      displayName: response.displayName,
      avatarUrl: response.avatarUrl,
    );
  }
}
```

See [Complete Worked Example](/best-practices/layered-architecture/worked-example) for the complete `user_repository` package with pubspec, barrel files, and error handling. See [Model Transformation Patterns](/best-practices/layered-architecture/model-transformation) for detailed transformation patterns between data and domain models.

## Dependency Graph

Each layer's `pubspec.yaml` enforces the architecture through path dependencies.

### Data Package (`packages/user_api_client/pubspec.yaml`)

```yaml
dependencies:
  # External packages only — no local dependencies
  http: ^1.4.0
  json_annotation: ^4.9.0
```

### Repository Package (`packages/user_repository/pubspec.yaml`)

```yaml
dependencies:
  equatable: ^2.0.7
  # Path dependency on data layer package
  user_api_client:
    path: ../user_api_client
```

### Root App (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.0
  # Repository packages only — data packages are transitive
  auth_repository:
    path: packages/auth_repository
  user_repository:
    path: packages/user_repository
```

**The app never depends on data packages directly.** Data packages are transitive dependencies through repositories. This enforces the layer boundary — business logic and presentation cannot bypass the repository layer.

## Data Flow

Step-by-step walkthrough: user taps "Load Profile" button.

1. **Presentation** dispatches event — `context.read<ProfileBloc>().add(ProfileLoadRequested(userId: '123'))`
2. **Business Logic** calls repository — Bloc handler invokes `_userRepository.getUser(event.userId)` and emits state based on the result
3. **Repository** calls data client — `UserRepository.getUser` delegates to `_userApiClient.getUser` and transforms the response into a domain `User`
4. **Data layer** communicates with external source — `UserApiClient.getUser` makes the HTTP request and returns a typed `UserResponse`
5. **Data flows back up** — Presentation rebuilds via `BlocBuilder` based on the new state

```dart
// lib/profile/bloc/profile_bloc.dart
Future<void> _onLoadRequested(
  ProfileLoadRequested event,
  Emitter<ProfileState> emit,
) async {
  emit(const ProfileState.loading());
  try {
    final user = await _userRepository.getUser(event.userId);
    emit(ProfileState.success(user: user));
  } on UserNotFoundException {
    emit(const ProfileState.notFound());
  } catch (_) {
    emit(const ProfileState.failure());
  }
}
```

See [Data Flow Walkthrough](/best-practices/layered-architecture/data-flow) for the full data flow walkthrough with code at each layer.

## App Bootstrap

The app's `main_<flavor>.dart` creates all data clients and repositories, then passes them to the `App` widget. `MultiRepositoryProvider` makes repositories available to the entire widget tree.

**`lib/main_development.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:auth_api_client/auth_api_client.dart';
import 'package:local_storage_client/local_storage_client.dart';
import 'package:auth_repository/auth_repository.dart';
import 'package:user_api_client/user_api_client.dart';
import 'package:user_repository/user_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'https://api.dev.example.com';

  // Data layer
  final authApiClient = AuthApiClient(baseUrl: baseUrl);
  final userApiClient = UserApiClient(baseUrl: baseUrl);
  final localStorageClient = LocalStorageClient();

  // Repository layer
  final authRepository = AuthRepository(
    authApiClient: authApiClient,
    localStorageClient: localStorageClient,
  );
  final userRepository = UserRepository(
    userApiClient: userApiClient,
  );

  runApp(
    App(
      authRepository: authRepository,
      userRepository: userRepository,
    ),
  );
}
```

Flavors change only the configuration (base URLs, API keys) — the architecture stays identical across development, staging, and production. See [Complete Worked Example](/best-practices/layered-architecture/worked-example) for the `App` widget with `MultiRepositoryProvider`.

## Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
| --- | --- | --- |
| Widget calls API client directly | Bypasses Repository and Business Logic layers — no transformation, no state management | Widget dispatches event → Bloc calls Repository → Repository calls API client |
| Repository imports another repository | Creates circular or tangled dependency graphs — breaks independent testability | Each repository is self-contained; combine data at the Bloc level if needed |
| Domain models in data layer | Couples external API shape to internal domain — API changes break the entire app | Data layer has response models; Repository layer has domain models with transformation |
| Business logic in repository | Repository becomes untestable monolith mixing orchestration with rules | Repository transforms data; Bloc/Cubit contains all business rules |
| `git:` or pub version for local packages | Breaks monorepo — changes require publish/push cycles instead of instant local edits | Use `path:` dependencies for all packages within the monorepo |
| Flutter imports in data/repository packages | Prevents packages from being used in Dart-only contexts (CLI tools, servers) | Scaffold with the `very_good_cli` MCP server `create dart_package` tool — no Flutter SDK dependency |
| One giant repository for everything | God-object with too many responsibilities — impossible to test in isolation | One repository per domain boundary (`user_repository`, `settings_repository`) |
| Importing `src/` directly | Breaks encapsulation — consumers depend on internal structure | Export public API through barrel files; import the package, never `src/` paths |

## Common Workflows

### Adding a New Data Source

1. Scaffold the package with the `very_good_cli` MCP server `create dart_package` tool: `<name>_api_client --output-directory packages`
2. Add external dependencies to `pubspec.yaml` (e.g., `http`, `json_annotation`)
3. Create response models in `lib/src/models/` with `fromJson`/`toJson`
4. Create barrel file `lib/src/models/models.dart` exporting all models
5. Implement the client class in `lib/src/<name>_api_client.dart`
6. Create the package barrel file `lib/<name>_api_client.dart` exporting `src/` contents
7. Write unit tests in `test/` mirroring `lib/` structure — see the **testing** skill
8. Use `very_good_cli` MCP server tool `test` against the package directory — pass `directory: 'packages/<name>_api_client'` to scope the run

### Adding a New Repository

1. Scaffold the package with the `very_good_cli` MCP server `create dart_package` tool: `<name>_repository --output-directory packages`
2. Add path dependencies to data layer packages in `pubspec.yaml`
3. Add `equatable` to dependencies for domain models
4. Create domain models in `lib/src/models/` extending `Equatable`
5. Create barrel file `lib/src/models/models.dart`
6. Implement the repository class with constructor-injected data clients
7. Add transformation logic from response models to domain models
8. Create the package barrel file `lib/<name>_repository.dart`
9. Write unit tests with mocked data clients — see the **testing** skill

### Connecting a Repository to a Feature

1. Add path dependency on the repository package to root `pubspec.yaml`
2. Create the repository in `main_<flavor>.dart` and pass it to `App`
3. Add `RepositoryProvider.value` in `App`'s `MultiRepositoryProvider`
4. Create the Bloc/Cubit with the repository injected — see the **bloc** skill
5. Build the Page/View with `BlocProvider` and `BlocBuilder` — see the **bloc** skill

## Additional Resources

- [Complete worked example](/best-practices/layered-architecture/worked-example) and [pubspec reference](/best-practices/layered-architecture/pubspec)
- [Model transformation patterns](/best-practices/layered-architecture/model-transformation) — data model vs domain model conversion
- [Package-level testing](/best-practices/layered-architecture/testing) — testing data clients and repositories in isolation
- For Bloc/Cubit patterns and Page/View separation — see the **bloc** skill
- For project scaffolding use the `very_good_cli` MCP server `create dart_package` tool
- For testing data clients, repositories, and Blocs — see the **testing** skill
