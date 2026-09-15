---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [static-security]
description: Form validation goes through a FormzInput subclass per field, and submit reads validated values off state instead of a controller.
---

This is the submit button on our login form:

ElevatedButton(
  onPressed: () => context.read<AuthBloc>().add(
    LoginRequested(
      email: _emailController.text,
      password: _passwordController.text,
    ),
  ),
  child: const Text('Login'),
);

Nothing is checked before this hits the API. Add the validation. Output Dart
code only.
