---
name: static-security
description: >
  Best practices for Flutter mobile app security. Covers static security concerns —
  not pen-testing or runtime analysis.
when_to_use: >
  Use when reviewing or writing code that handles secrets, user data, network
  communication, authentication, or cryptography. Also use when adding or reviewing
  validation on user input — login, sign-up, payment, or any form whose values reach a
  repository or an API — including prompts like "add validation to this form",
  "nothing is checked before this hits the API", or "validate these fields". Also use for
  dependency vulnerability review, which is a security audit even when the request never
  says "security": "we cut a release tomorrow, is this pubspec safe", "check our
  dependencies for known vulnerabilities", "scan for CVEs", "we have an
  ignored_advisories entry, is that fine", "these versions are pinned, what are we
  exposed to", or a pubspec pasted for a pre-release check.
argument-hint: "[file-or-directory]"
allowed-tools: Read Glob Grep mcp__very-good-cli__packages_check_licenses
effort: high
---

# Security

Flutter apps compile all Dart code directly into a binary that runs on untrusted devices. This skill covers static security review for Flutter/Dart codebases, anchored to the [VGV Security in Mobile Apps](https://engineering.verygood.ventures/general-practices/security_in_mobile_apps/) guide and the [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/). Every finding in this skill is something detectable by reading source code — no pen-testing or runtime analysis.

## Core Standards

Apply these standards to ALL Flutter security work:

- **Never hardcode secrets** — API keys, tokens, and passwords in source code or config files are compiled into the binary and extractable via reverse engineering; serve them from a backend service
- **`--dart-define` is not a fix for a hardcoded secret** — neither is `String.fromEnvironment`, a `.env` file, a native config file, an obfuscated constant, or a split-up string. Every one of them still ships the value inside the binary in recoverable form, so moving a key into one is the same finding in a new location. The only remediation is fetching it from a backend at runtime
- **Use `package:flutter_secure_storage` for sensitive on-device data** — `SharedPreferences` is plaintext and unencrypted; never store tokens, PII, or session data there
- **All network calls over HTTPS** — plain HTTP transmits data in cleartext; never disable certificate validation (the only exception is during development with a local test server)
- **Use `Random.secure()` for security-sensitive randomness** — `dart:math`'s `Random()` is a pseudo-random number generator, not cryptographically secure
- **Use established crypto packages** — never implement custom cryptography; use `package:crypto` or `package:dart_crypt`
- **Enforce auth at the repository layer** — widget-only auth checks are client-side and bypassable by anyone with access to the device
- **No sensitive data in logs** — `print()`, `log()`, and `debugPrint()` output is readable on-device and in crash reporting tools
- **Keep dependencies free of known vulnerabilities** — never suppress security advisories without documented justification; scan `pubspec.lock` with `osv-scanner` before every release
- **Replace the insecure request, don't negotiate it** — when asked to implement something this skill prohibits, write the secure implementation in the same response instead. Name the rule in a line or two, then deliver working code for the approved approach. Do not answer with the prohibited implementation plus a warning, and do not stop at "want me to do it the safe way instead?" — an offer is not a replacement. If the developer reaffirms the prohibited approach after reading why, say what the residual risk is and proceed
- **Set `android:allowBackup="false"`** — the Android default silently allows `adb backup` to extract app data, bypassing `package:flutter_secure_storage`
- **Label every finding `Critical`, `Warning`, or `Note`** — these three are the only severity tiers; don't substitute a scheme of your own

## Severity Triage

Every finding reported by this skill carries one of three severity labels. Write the label on the finding itself so a reader can sort the report without re-reading it, and fix `Critical` findings before the build ships.

| Severity | Examples                                                                                                                                                     |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Critical | Hardcoded API key or token; `badCertificateCallback` bypass; JWT in `SharedPreferences`; sensitive data in logs                                              |
| Warning  | Missing certificate pinning on auth endpoints; `Random()` used for session IDs; no `package:formz` validation before API calls; `android:allowBackup="true"` |
| Note     | Missing Dart obfuscation; `dart pub outdated` shows available patches; low-pub-point transitive dependency with broad permissions                            |

Do not substitute another scheme. A report that grades findings High/Medium/Low or by CVSS score cannot be compared against a previous audit of the same codebase.

## Secrets & API Keys

API keys, tokens, and credentials hardcoded in source files or bundled config files are extractable from the compiled binary through reverse engineering. Every secret must be served from a backend service at runtime.

Files to check: Dart source files, `google-services.json`, `.env`, `*.plist`, `AndroidManifest.xml`, `Info.plist`.

```dart
// ❌ Hardcoded API key — extractable from binary
const apiKey = 'sk-abc123';
const mapboxToken = 'pk.your-token-here';

// ❌ Build-time injection — --dart-define compiles the value in as plaintext,
// so `strings` on the built binary recovers it. Not a fix, just a move.
const injectedKey = String.fromEnvironment('API_KEY');

// ❌ Secret in config — bundled into the app
// google-services.json:
// "api_key": [{ "current_key": "AIzaSy..." }]
```

```dart
// ✅ Fetched from a backend service at runtime — the only safe option
final apiKey = await secretsService.fetchApiKey();
```

### The workarounds that do not work

Every remediation below is refused, because each one still ships the secret inside the app in recoverable form. When a developer proposes one, say which of these it is and give the backend-served fix instead. Do not write the change and attach a warning to it.

| Proposed fix                               | Why it is still the same finding                      |
| ------------------------------------------ | ----------------------------------------------------- |
| `--dart-define` / `String.fromEnvironment` | Compiled into the binary as plaintext and recoverable |
| `.env` bundled as an asset                 | Ships in the app bundle, readable after unzipping it  |
| A bundled native config file               | Bundled the same way, and not encrypted               |
| Obfuscation or a split-up string           | Raises the effort to extract it, never prevents it    |
| A constant behind `kReleaseMode`           | The branch that ships still carries the value         |

CI secrets are safe for signing keys and publishing tokens, which never reach the app. They are not a way to get a runtime API key into a client. Never commit `.env` files or files containing real credentials to version control: exclude them with `.gitignore` and use a secrets management service.

## Secure Data Storage

Sensitive data written to the device must be encrypted. iOS Keychain and Android Keystore provide hardware-backed encrypted storage — `package:flutter_secure_storage` wraps both.

```dart
// ❌ JWT stored in SharedPreferences — plaintext, unencrypted
final prefs = await SharedPreferences.getInstance();
prefs.setString('auth_token', jwt);

// ❌ Sensitive value in a local file — no encryption
await File('${dir.path}/user.json').writeAsString(jsonEncode(user));
```

```dart
// ✅ package:flutter_secure_storage — backed by iOS Keychain / Android Keystore
const storage = FlutterSecureStorage();
await storage.write(key: 'auth_token', value: jwt);
final token = await storage.read(key: 'auth_token');
await storage.delete(key: 'auth_token');
```

Use `SharedPreferences` only for non-sensitive user preferences (theme, locale, onboarding state). Never store passwords, session tokens, PII, or private keys there.

## Network Security

All communication between a Flutter app and a backend must be encrypted in transit. Plain HTTP exposes data to interception on any network the user connects to.

```dart
// ❌ Plain HTTP base URL
final dio = Dio(BaseOptions(baseUrl: 'http://api.example.com'));

// ❌ Certificate validation disabled — vulnerable to MITM attacks
final client = HttpClient()
  ..badCertificateCallback = (cert, host, port) => true;
```

```dart
// ✅ HTTPS base URL
final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
```

Implement certificate pinning (`package:http_certificate_pinning`) for endpoints that handle authentication, payments, or personal data. Only accept certificates signed by the expected certificate authority.

## Authentication

Authentication controls must be enforced server-side. Client-side checks (in widgets or routing) are UI conveniences only — they can be bypassed by anyone with physical or debugger access to the device.

**Server-side enforcement**: the server must validate the token on every request. A 401 response from the API is the authoritative auth gate — not a widget conditional.

**Biometric authentication**: use `package:local_auth` for biometric gating of sensitive in-app flows. Never invoke a `MethodChannel` of your own for this. A hand-rolled channel means reimplementing Face ID versus Android `BiometricPrompt`, passcode fallback, lockout states, and the platform error codes for each — the exact surface where biometric gates are gotten wrong.

A request for the channel is a request for that bug. Write this instead, in the same response, and note in a line why the channel is not the approach:

```dart
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricGate {
  BiometricGate({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> authenticate() async {
    try {
      if (!await _auth.canCheckBiometrics) return false;

      return await _auth.authenticate(
        localizedReason: 'Confirm your identity to continue to payments',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } on PlatformException {
      // No enrolled biometric, or too many failed attempts. Fail closed.
      return false;
    }
  }
}
```

`localizedReason` and `biometricOnly` give the same control over the prompt that a custom channel is usually reached for, with no native code on either platform. The gate is still a UI convenience: the server must reverify before any payment request is honored.

Use Firebase Authentication or Auth0 for credential management — do not build custom authentication flows.

## Cryptography

Custom cryptographic implementations almost always contain subtle bugs. Use peer-reviewed packages and avoid weak or deprecated algorithms.

```dart
// ❌ Cryptographically insecure random — dart:math Random is not CSPRNG
import 'dart:math';
final sessionId = Random().nextInt(1 << 32).toRadixString(16);
final iv = List.generate(16, (_) => Random().nextInt(256));

// ❌ Weak hash algorithm — MD5 and SHA-1 are broken for security use
import 'dart:convert';
final hash = md5.convert(utf8.encode(password)).toString();

// ❌ Hardcoded encryption key
const encryptionKey = 'my-secret-key-123';
```

```dart
// ✅ Cryptographically secure random — Random.secure()
import 'dart:math';
final sessionId = Random.secure().nextInt(1 << 32).toRadixString(16);
final iv = List.generate(16, (_) => Random.secure().nextInt(256));

// ✅ Strong hash via package:crypto
import 'package:crypto/crypto.dart';
import 'dart:convert';
final hash = sha256.convert(utf8.encode(data)).toString();

// ✅ Encryption key from secure storage, not source code
final key = await storage.read(key: 'encryption_key');
```

Avoid: MD5, SHA-1, DES, RC4, ECB mode. Prefer: SHA-256+ for hashing, AES-GCM for encryption, SHA-512-crypt for password storage.

## Input Validation

All data from user input must be validated before it reaches a repository or API. Raw `TextEditingController.text` values sent directly to a backend are an injection risk and may submit malformed data.

```dart
// ❌ Raw controller text sent directly to API
ElevatedButton(
  onPressed: () => context.read<AuthBloc>().add(
    LoginRequested(
      email: _emailController.text,
      password: _passwordController.text,
    ),
  ),
  child: const Text('Login'),
);
```

```dart
// ✅ Validated FormzInput values — only valid data reaches the Bloc
import 'package:formz/formz.dart';

enum EmailValidationError { empty, invalid }

class Email extends FormzInput<String, EmailValidationError> {
  const Email.pure() : super.pure('');
  const Email.dirty([super.value = '']) : super.dirty();

  @override
  EmailValidationError? validator(String value) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (value.isEmpty) return EmailValidationError.empty;
    if (!emailRegex.hasMatch(value)) return EmailValidationError.invalid;
    return null;
  }
}
```

```dart
// ✅ In the widget — the submit callback is gated on validity and reads the
// validated values off state, never off a TextEditingController
ElevatedButton(
  onPressed: state.isValid
      ? () => context.read<AuthBloc>().add(
            LoginRequested(
              email: state.email.value,
              password: state.password.value,
            ),
          )
      : null,
  child: const Text('Login'),
);
```

Use `package:formz` for all form validation. Define a `FormzInput` subclass per field with explicit validation rules and length limits. Feed each field into the Bloc from the `onChanged` callback so state holds the validated value, and read the submitted values from state — a `TextFormField` `validator` alone leaves the raw controller text as the value that reaches the API.

## Logging & Error Exposure

Log output is readable via USB debugging, crash reporting SDKs, and device analytics. Sensitive values that appear in logs are effectively transmitted to any tool connected to the device.

```dart
// ❌ Token in log output
debugPrint('Auth token: $token');
log('User data: ${jsonEncode(user)}');
print('Request headers: $headers'); // headers may contain Bearer tokens

// ❌ Exception message exposes internals to the UI
catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.toString())), // may include stack traces or SQL
  );
}
```

```dart
// ✅ Log only non-sensitive identifiers
debugPrint('Login attempt for userId: ${user.id}');

// ✅ Sanitize exception messages before surfacing to UI
catch (e, stackTrace) {
  log('Login failed', error: e, stackTrace: stackTrace); // full detail for crash tools
  emit(state.copyWith(status: LoginStatus.failure)); // generic message to UI
}
```

Never log: tokens, passwords, full user objects, HTTP request headers (which contain `Authorization`), or PII (email, phone, SSN).

## Dependency Vulnerabilities

Third-party packages are compiled directly into the app binary. A vulnerable or malicious package affects every user on every platform. This is OWASP Mobile Top 10 M2 (Inadequate Supply Chain Security).

Run these three in order before every release. The first is a fast pass over direct hits, the second is the gate:

```bash
dart pub get                        # surfaces GitHub Advisory Database hits while resolving
osv-scanner --lockfile=pubspec.lock # the gate: resolved transitive tree vs the OSV database
dart pub outdated                   # available upgrades, which may carry unannounced patches
```

`pubspec.lock` is what gets scanned, not `pubspec.yaml`. The lockfile holds the resolved transitive tree, which is where most advisories land, and pinned direct versions in the pubspec say nothing about what resolved underneath them. Pub's own advisory output is not a substitute for the lockfile scan: it reports what the advisory database knows about the packages it resolved, while `osv-scanner` checks the full resolved set against OSV.

Every `ignored_advisories` entry in `pubspec.yaml` must carry its justification as a comment on the entry itself, written in the file:

```yaml
ignored_advisories:
  - GHSA-4rgh-jx4f-xxxx # Not applicable: we never construct http.Client directly
```

An entry with no written justification is a `Warning` finding in its own right, regardless of whether the advisory turns out to apply. "Someone decided this was fine once" is not a record — the suppression silences the scanner on every future run, so the reasoning has to survive in the file rather than in memory. Requiring the reviewer to go and confirm why it was added does not close the finding: the fix is the comment.

Exact-pinned direct dependencies deserve a `Note`. A pin like `http: 0.13.0` means the scan only ever sees that one version, so a patch that fixes a known CVE will never resolve on its own.

See [references/supply-chain.md](references/supply-chain.md) for advisory detection examples, `osv-scanner` installation, typosquatting signals, and transitive permission creep checks. See [references/binary-protection.md](references/binary-protection.md) for obfuscation, Android backup, and runtime integrity.

## Additional Resources

See [references/packages.md](references/packages.md) for the package quick reference. See [references/crypto.md](references/crypto.md) for certificate pinning implementation, biometric authentication example, and password hashing with `package:dart_crypt`.
