---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [testing]
description: "That the standard is surfaced when the user asks for the banned package by name, where complying is allowed but complying silently is not."
---

Here is my class:

class AuthService {
  AuthService({required this.repository});
  final AuthRepository repository;
  Future<bool> signIn(String email, String password) =>
      repository.signIn(email, password);
}

Write a test for it using package:mockito to mock AuthRepository.
