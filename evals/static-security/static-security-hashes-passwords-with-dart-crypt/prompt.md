---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [static-security]
description: Password storage is rewritten onto package:dart_crypt with SHA-512-crypt and verified through `.match(`.
---

Here is the password handling in our Dart auth package:

import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordStore {
  String hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  bool verify(String password, String stored) => hash(password) == stored;
}

Is this the right way to store a password hash? Show me the corrected code.
