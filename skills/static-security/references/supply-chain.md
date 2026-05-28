# Supply Chain Security

## Typosquatting Signals

Flag packages in `pubspec.yaml` that match any of these patterns:

- Name differs from a well-known package by one character, a dash/underscore swap, or transposed letters (e.g., `flutter-secure-storage` vs `flutter_secure_storage`, `bloc_fluter` vs `flutter_bloc`)
- No verified publisher on pub.dev (check the publisher badge on the package's pub.dev page) and fewer than 100 pub points, while performing high-privilege operations: file I/O, network requests, camera, Keychain/Keystore access
- Publisher's GitHub repo URL does not match the package's declared homepage

## Transitive Permission Creep

Review `AndroidManifest.xml` for permissions that no first-party Dart code requires. Permissions can be merged in silently by transitive dependencies:

```xml
<!-- Flag: does any first-party code actually use READ_CONTACTS? -->
<uses-permission android:name="android.permission.READ_CONTACTS" />
```

Trace which package introduced an unexpected permission:

```bash
flutter pub deps --style=tree
```

Apply the same check to `NSUsageDescription` keys in `ios/Runner/Info.plist`.

## Advisory Detection

**Real-world example**: `flutter_downloader` (99% pub.dev popularity) contained SQL injection and arbitrary file write vulnerabilities prior to v1.11.2, enabling session token theft from banking and government apps.

`dart pub get` automatically surfaces hits from the GitHub Advisory Database:

```text
http 0.13.0 (affected by advisory: GHSA-4rgh-jx4f-xxxx, 1.2.0 available)
```

Any entry in `ignored_advisories` in `pubspec.yaml` must have a documented justification comment:

```yaml
# pubspec.yaml
ignored_advisories:
  - GHSA-4rgh-jx4f-xxxx # Not applicable: we do not use the affected http.Client constructor
```

Check for packages with available upgrades that may include unannounced security patches:

```bash
dart pub outdated
```

## osv-scanner Installation

Scan `pubspec.lock` against the [OSV database](https://osv.dev) for known CVEs.

```bash
# macOS
brew install osv-scanner

# Linux / CI — download binary from https://github.com/google/osv-scanner/releases
osv-scanner --lockfile=pubspec.lock
# Output: table of vulnerable packages with CVE links and affected versions
```
