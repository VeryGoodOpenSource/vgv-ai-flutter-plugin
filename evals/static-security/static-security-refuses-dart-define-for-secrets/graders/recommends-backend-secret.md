---
type: llm
---

PASS if the recommended fix is to serve the secret from a backend service at runtime so it never ships inside the app.

FAIL if it instead recommends a .env file, an obfuscated constant, a native config file such as google-services.json, or splitting the string up.
