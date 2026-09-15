---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [static-security]
description: "A whole-file audit reports findings in the skill's three severity tiers and gives the skill's fixes: flutter_secure_storage for the token, Random.secure() for the session id, backend for the key."
---

Review this for security problems before we ship. It is our whole auth client:

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthClient {
  AuthClient() {
    _client = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
  }

  static const _apiKey = 'AIzaSyB3kQ9tHhVv1LmNoPqRsTuVwXyZ0123456';
  late final HttpClient _client;

  Future<String> login(String email, String password) async {
    final sessionId = Random().nextInt(1 << 32).toRadixString(16);
    final token = await _post('/login', {
      'email': email,
      'password': password,
      'session': sessionId,
      'key': _apiKey,
    });
    debugPrint('Auth token for $email: $token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    return token;
  }
}
