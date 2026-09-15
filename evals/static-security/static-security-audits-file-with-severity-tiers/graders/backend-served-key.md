---
type: llm
---

PASS if the fix given for the hardcoded key is to fetch it from a backend service at runtime, and moving it to --dart-define, String.fromEnvironment, a .env file, or any other build-time constant is either absent or explicitly rejected as insufficient.

FAIL if any build-time constant is offered as an acceptable fix, or if the fix given for the hardcoded key is anything other than fetching it from a backend service at runtime, such as moving it to secure storage or only saying it must not be hardcoded.
