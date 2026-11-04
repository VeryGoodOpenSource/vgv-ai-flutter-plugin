---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [bloc]
description: "Page/View separation: the Page's only job is BlocProvider, the View consumes state, and no repository call sits in a build method."
---

Build the login screen for this app and wire it to LoginBloc. This is the bloc's public API
as it exists in `lib/login/bloc/`; treat it as authoritative. Output Dart code only.

```dart
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required AuthenticationRepository authenticationRepository});
}

sealed class LoginEvent extends Equatable {}

final class LoginEmailChanged extends LoginEvent {
  LoginEmailChanged(this.email);
  final String email;
}

final class LoginPasswordChanged extends LoginEvent {
  LoginPasswordChanged(this.password);
  final String password;
}

final class LoginSubmitted extends LoginEvent {}

enum LoginStatus { initial, inProgress, success, failure }

final class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.email = '',
    this.password = '',
  });

  final LoginStatus status;
  final String email;
  final String password;
}
```

`AuthenticationRepository` is provided above the app with `RepositoryProvider`.
