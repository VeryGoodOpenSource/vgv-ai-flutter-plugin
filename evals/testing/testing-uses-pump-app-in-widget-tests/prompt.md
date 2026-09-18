---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [testing]
description: "Widget tests wrap through the shared `pumpApp` helper and drive the view with a MockBloc or MockCubit rather than a real bloc."
---

Write a widget test for `LoginView`. It should assert that a SnackBar carrying the error
message appears when the bloc emits a failure state. Our project already has the usual
shared widget-test helpers available under `test/helpers/`. Output Dart code only.

These are the types, and this description is authoritative over anything on disk:

```dart
class LoginView extends StatelessWidget { const LoginView({super.key}); }

class LoginBloc extends Bloc<LoginEvent, LoginState> { ... }

sealed class LoginState extends Equatable { const LoginState(); }

final class LoginInitial extends LoginState {}

final class LoginFailure extends LoginState {
  const LoginFailure(this.errorMessage);
  final String errorMessage;
}
```
