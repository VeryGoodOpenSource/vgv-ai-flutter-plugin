---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [create-project]
description: Negative control. A one-field edit to an existing class leaves the skill dormant.
---

Here is my existing class:
class ApiConfig {
  const ApiConfig({required this.baseUrl, required this.timeout});
  final String baseUrl;
  final Duration timeout;
}
Add a `retryCount` int field with a default of 3. Return only the updated class.
