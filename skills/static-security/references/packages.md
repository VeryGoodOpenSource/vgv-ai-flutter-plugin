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

The `Critical` / `Warning` / `Note` tiers and their examples live in the `## Severity Triage` section of `SKILL.md`. Label every finding from that table.
