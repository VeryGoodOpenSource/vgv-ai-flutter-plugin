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
  auth_repository:
    path: packages/auth_repository
  user_repository:
    path: packages/user_repository
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
