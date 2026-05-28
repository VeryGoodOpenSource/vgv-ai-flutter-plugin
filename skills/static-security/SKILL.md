---
name: vgv-static-security
description: >
  Best practices for Flutter mobile app security. Covers static security concerns —
  not pen-testing or runtime analysis.
when_to_use: >
  Use when reviewing or writing code that handles secrets, user data, network
  communication, authentication, or cryptography.
argument-hint: "[file-or-directory]"
allowed-tools: Read Glob Grep mcp__very-good-cli__packages_check_licenses
effort: high
---

# Security

Flutter apps compile all Dart code directly into a binary that runs on untrusted devices. This skill covers static security review for Flutter/Dart codebases, anchored to the [VGV Security in Mobile Apps](https://engineering.verygood.ventures/general-practices/security_in_mobile_apps/) guide and the [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/). Every finding in this skill is something detectable by reading source code — no pen-testing or runtime analysis.

## Core Standards

Apply these standards to ALL Flutter security work:

- **Never hardcode secrets** — API keys, tokens, and passwords in source code or config files are compiled into the binary and extractable via reverse engineering; serve them from a backend service
- **Use `package:flutter_secure_storage` for sensitive on-device data** — `SharedPreferences` is plaintext and unencrypted; never store tokens, PII, or session data there
- **All network calls over HTTPS** — plain HTTP transmits data in cleartext; never disable certificate validation (the only exception is during development with a local test server)
- **Use `Random.secure()` for security-sensitive randomness** — `dart:math`'s `Random()` is a pseudo-random number generator, not cryptographically secure
- **Use established crypto packages** — never implement custom cryptography; use `package:crypto` or `package:dart_crypt`
- **Enforce auth at the repository layer** — widget-only auth checks are client-side and bypassable by anyone with access to the device
- **No sensitive data in logs** — `print()`, `log()`, and `debugPrint()` output is readable on-device and in crash reporting tools
- **Keep dependencies free of known vulnerabilities** — never suppress security advisories without documented justification; scan `pubspec.lock` with `osv-scanner` before every release
- **Set `android:allowBackup="false"`** — the Android default silently allows `adb backup` to extract app data, bypassing `package:flutter_secure_storage`

## Secrets & API Keys

API keys, tokens, and credentials hardcoded in source files or bundled config files are extractable from the compiled binary through reverse engineering. Every secret must be served from a backend service at runtime.

Files to check: Dart source files, `google-services.json`, `.env`, `*.plist`, `AndroidManifest.xml`, `Info.plist`.

```dart
// ❌ Hardcoded API key — extractable from binary
const apiKey = 'sk-abc123';
const mapboxToken = 'pk.your-token-here';

// ❌ Secret in config — bundled into the app
// google-services.json:
// "api_key": [{ "current_key": "AIzaSy..." }]
```

```dart
// ✅ Fetched from a backend service at runtime — the only safe option
final apiKey = await secretsService.fetchApiKey();
```

Never commit `.env` files or files containing real credentials to version control. Use `.gitignore` to exclude them and a secrets management service instead. Note: `--dart-define` / `String.fromEnvironment` compile values into the binary as plaintext and are extractable via reverse engineering — they are not a safe alternative to backend-served secrets.

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

**Biometric authentication**: use `package:local_auth` for biometric gating of sensitive in-app flows — do not invoke platform channels directly.

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

// In the widget — only submit when the form is valid
if (state.status.isValidated) {
  context.read<AuthBloc>().add(
    LoginRequested(email: state.email.value, password: state.password.value),
  );
}
```

Use `package:formz` for all form validation. Define a `FormzInput` subclass per field with explicit validation rules and length limits.

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

- Run `dart pub get` to surface GitHub Advisory Database hits
- Any `ignored_advisories` entry in `pubspec.yaml` must have a documented justification comment
- Scan `pubspec.lock` with `osv-scanner` before every release
- Run `dart pub outdated` to check for available security patches

See [references/supply-chain.md](references/supply-chain.md) for advisory detection examples, `osv-scanner` installation, typosquatting signals, and transitive permission creep checks. See [references/binary-protection.md](references/binary-protection.md) for obfuscation, Android backup, and runtime integrity.

## Additional Resources

See [references/packages.md](references/packages.md) for the package quick reference and severity triage guide. See [references/crypto.md](references/crypto.md) for certificate pinning implementation, biometric authentication example, and password hashing with `package:dart_crypt`.
