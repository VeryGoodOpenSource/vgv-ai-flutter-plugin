---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [bloc]
description: "Two Core Standards at once: blocTest from package:bloc_test for every bloc test, and package:mocktail for the repository double."
---

Here is my bloc:

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required this.authRepository}) : super(LoginInitial());
  final AuthRepository authRepository;
}

Write the unit tests for it. It calls authRepository.signIn. Output Dart code only.
