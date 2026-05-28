# Cryptography Reference

## Certificate Pinning

Implement certificate pinning (`package:http_certificate_pinning`) for endpoints that handle authentication, payments, or personal data. Only accept certificates signed by the expected certificate authority.

```dart
final result = await HttpCertificatePinning.check(
  serverURL: 'https://api.example.com',
  headerHttp: {},
  sha: SHA.SHA256,
  allowedSHAFingerprints: ['AA:BB:CC:...'],
  timeout: 60,
);
if (result != 'CONNECTION_SECURE') {
  throw CertificatePinningException();
}
```

## Biometric Authentication

Use `package:local_auth` for biometric gating of sensitive in-app flows. Do not invoke platform channels directly — the abstraction handles platform differences and reduces implementation error.

```dart
// ❌ Custom biometric implementation via platform channel — error-prone
final result = await platform.invokeMethod('checkFingerprint');

// ✅ Biometric authentication via package:local_auth
final auth = LocalAuthentication();
final didAuthenticate = await auth.authenticate(
  localizedReason: 'Confirm your identity to view this information',
  options: const AuthenticationOptions(biometricOnly: true),
);
```

## Password Hashing

Use `package:dart_crypt` for password storage. SHA-512-crypt is a slow, salted algorithm designed for passwords — unlike `sha256` from `package:crypto`, which is fast and unsuitable for password hashing.

```dart
import 'package:dart_crypt/dart_crypt.dart';

// Hash on registration / password change
final hashed = Crypt.sha512(password);

// Verify on login
final isValid = hashed.match(inputPassword);
```
