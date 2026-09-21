---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [testing]
description: "The whole unit-test shape at once: private `_Mock` class, `late` + `setUp` inside a group, and names that read as sentences with `$Type` interpolation so renames propagate."
---

Here is my class:

class UserRepository {
  UserRepository({required this.apiClient});
  final ApiClient apiClient;
  Future<User> getUser(String id) => apiClient.fetchUser(id);
}

Write unit tests for it. getUser throws UserNotFoundException on a 404. Output Dart code only.
