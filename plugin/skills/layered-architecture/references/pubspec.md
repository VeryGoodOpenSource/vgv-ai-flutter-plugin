# pubspec.yaml Reference

## Data Package

```yaml
name: weather_api_client
description: HTTP client for the Weather API.
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

## Repository Package

```yaml
name: weather_repository
description: Repository for weather data.
version: 0.1.0+1
publish_to: none

environment:
  sdk: ^3.11.0

dependencies:
  equatable: ^2.0.7
  weather_api_client:
    path: ../weather_api_client

dev_dependencies:
  mocktail: ^1.0.0
  test: ^1.25.0
  very_good_analysis: ^7.0.0
```

## Root App

```yaml
name: my_app
description: A Very Good App.
version: 1.0.0+1
publish_to: none

environment:
  sdk: ^3.11.0
  flutter: ^3.29.0

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.0
  auth_api_client:
    path: packages/auth_api_client
  auth_repository:
    path: packages/auth_repository
  user_api_client:
    path: packages/user_api_client
  user_repository:
    path: packages/user_repository
  weather_api_client:
    path: packages/weather_api_client
  weather_repository:
    path: packages/weather_repository

dev_dependencies:
  bloc_test: ^9.1.0
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  very_good_analysis: ^7.0.0

flutter:
  uses-material-design: true
```

## Shared Flutter Package

Used for shared widgets or themes that depend on the Flutter SDK.

```yaml
name: app_ui
description: Shared UI components and theme for the app.
version: 0.1.0+1
publish_to: none

environment:
  sdk: ^3.11.0
  flutter: ^3.29.0

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: ^7.0.0
```

## Layer Boundaries in `pubspec.yaml`

Path dependencies point one direction only. The root app is the one package that declares
both layers, because its bootstrap constructs the data clients it injects into repositories.

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
  # Repositories, plus each data package main_<flavor>.dart constructs
  auth_api_client:
    path: packages/auth_api_client
  auth_repository:
    path: packages/auth_repository
  user_api_client:
    path: packages/user_api_client
  user_repository:
    path: packages/user_repository
```

## The Import Boundary

With the data packages declared, `depend_on_referenced_packages` no longer flags a bloc that
imports one. The boundary is the import rule: only the app's entrypoints and bootstrap import
a data package.

The entrypoints and bootstrap are the files that construct the clients. In a Very Good CLI
app they are `lib/main_<flavor>.dart` and `lib/bootstrap.dart`. A single-flavor app has
`lib/main.dart`. Some apps group them in a directory, such as `lib/main/main_development.dart`
and `lib/main/bootstrap/bootstrap.dart`. Treat whichever files the app uses as the allowed set.

Check the boundary after wiring a repository. Grep `lib/` and `test/` for each data package's
imports:

```text
^(import|export) 'package:user_api_client/
```

The check passes when every hit is an entrypoint or bootstrap file. Fix any other hit in
the code:

- A bloc or widget that names a data-layer model, enum, or exception gets a domain type
  instead. The repository defines it and maps to it, the way `UserRepository` catches
  `UserApiException` and throws its own `UserNotFoundException`.
- A bloc or widget that calls the client calls a repository method instead.
- An app test mocks the repository, never the client.

When the data layer is a third-party SDK used without a wrapper package, such as
`package:firebase_auth` or `package:firebase_storage`, the same rule covers its imports. Its
package name does not mark it as data layer, so add each SDK the repositories take to the
grep by name.
