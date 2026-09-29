---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [layered-architecture]
description: "Bootstrap injection under a request to keep the app pubspec to repositories only: the repository requires its client and never builds one, main_development.dart constructs it, and the app pubspec declares the data package."
---

My monorepo has a data layer package at `packages/weather_api_client`. It is not in your working directory, so treat this as its exact public API:

```dart
class WeatherApiClient {
  WeatherApiClient({required String baseUrl});

  Future<WeatherResponse> getWeather(String city);
}

class WeatherResponse {
  const WeatherResponse({required this.city, required this.temperature});

  final String city;
  final double temperature;
}
```

Create `packages/weather_repository` with a `WeatherRepository` whose `getWeather(String city)` maps the response to a `Weather` domain model, and wire it into the app so features can reach it. I want the app's pubspec to list only `weather_repository` so it stays clean. The dev API is at `https://api.dev.example.com`. Show the Dart code for the repository and `lib/main_development.dart`, and the app pubspec changes.
