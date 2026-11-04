---
type: llm
---

PASS if the fix given for the hardcoded key keeps it on a backend: either the app fetches it from a backend service at runtime, or a backend (microservice, cloud function, or proxy) holds the key and calls the API on the app's behalf so the key never reaches the client. Moving it to --dart-define, String.fromEnvironment, a .env file, or any other build-time constant must be either absent or explicitly rejected as insufficient.

FAIL if any build-time constant is offered as an acceptable fix, or if the fix given for the hardcoded key does not put it on a backend, such as moving it to secure storage, obfuscating it, or only saying it must not be hardcoded.
