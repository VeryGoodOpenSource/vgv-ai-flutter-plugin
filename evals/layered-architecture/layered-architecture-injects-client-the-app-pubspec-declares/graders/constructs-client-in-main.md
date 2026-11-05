---
type: llm
---

PASS if lib/main_development.dart constructs a WeatherApiClient with the base URL `https://api.dev.example.com` and passes it into the WeatherRepository constructor.

FAIL if main_development.dart constructs WeatherRepository without passing it a WeatherApiClient, or if the WeatherApiClient is constructed inside the repository package, for example in a factory constructor or a default parameter value.
