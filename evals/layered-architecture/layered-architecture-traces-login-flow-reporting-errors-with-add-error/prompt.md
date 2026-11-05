---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [layered-architecture]
description: "Bottom-up data flow per the synced VGE architecture standard: the bloc reaches the API only through the repository, and its catch reports the failure with addError(error, stackTrace) before emitting a failure state."
---

My app has a data package at `packages/api_client`. It is not in your working directory, so treat this as its exact public API:

```dart
class ApiClient {
  ApiClient({required String baseUrl});

  Future<void> makeRequest({
    required String url,
    required Map<String, dynamic> data,
  });
}
```

The login screen's submit button has to log the user in by POSTing the email and password, which `LoginBloc` already holds in its state, to `/login`. Show the code at every level from the button down to `ApiClient`, including what happens when the request fails.
