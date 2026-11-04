---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [static-security]
description: "Stopping a proxy-CA interception follows the synced VGE Insecure Communication standard: certificate pinning through package:http_certificate_pinning with allowed SHA fingerprints."
---

A pentester installed their own proxy CA on a test phone and read every request our app sends to https://api.acme-pay.com, card tokens included. This is our whole payments client:

import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentsClient {
  PaymentsClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> charge(String cardToken, int amountCents) async {
    await _client.post(
      Uri.parse('https://api.acme-pay.com/v1/charges'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': cardToken, 'amount': amountCents}),
    );
  }
}

Fix the client so that attack no longer works. Output Dart code only.
