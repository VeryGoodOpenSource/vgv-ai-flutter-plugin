# Package Quick Reference

| Package                            | Replaces / Prevents                                    | Category                   |
| ---------------------------------- | ------------------------------------------------------ | -------------------------- |
| `package:flutter_secure_storage`   | `SharedPreferences` for sensitive data                 | Secure Storage             |
| `package:http_certificate_pinning` | Certificate spoofing / MITM attacks                    | Network Security           |
| `package:local_auth`               | Custom biometric implementations                       | Authentication             |
| `package:crypto`                   | Weak hash algorithms, custom crypto                    | Cryptography               |
| `package:dart_crypt`               | Insecure password storage (SHA-512-crypt)              | Cryptography               |
| `package:formz`                    | Raw `TextEditingController` input without validation   | Input Validation           |
| `osv-scanner`                      | Undetected CVEs in `pubspec.lock`                      | Dependency Vulnerabilities |
| `package:freerasp`                 | Compromised device / repackaged app (runtime)          | Binary Protection          |

## Severity Guide

When auditing a codebase with this skill, triage findings using these tiers:

| Severity | Examples                                                                                                                                                     |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Critical | Hardcoded API key or token; `badCertificateCallback` bypass; JWT in `SharedPreferences`; sensitive data in logs                                              |
| Warning  | Missing certificate pinning on auth endpoints; `Random()` used for session IDs; no `package:formz` validation before API calls; `android:allowBackup="true"` |
| Note     | Missing Dart obfuscation; `dart pub outdated` shows available patches; low-pub-point transitive dependency with broad permissions                            |
