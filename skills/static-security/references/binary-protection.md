# Binary Protection

These are build and configuration concerns rather than source code patterns, but they compound the impact of every other vulnerability category.

## Dart Obfuscation

Enable in all release builds to make reverse engineering significantly harder:

```bash
flutter build apk --obfuscate --split-debug-info=build/symbols/
flutter build ipa --obfuscate --split-debug-info=build/symbols/
```

## Android Backup

`android:allowBackup="true"` (the Android default) allows `adb backup` to extract app data, including anything stored by `package:flutter_secure_storage`:

```xml
<!-- AndroidManifest.xml -->
<!-- ❌ Default — allows ADB backup of app data -->
<application android:allowBackup="true" ...>

<!-- ✅ Disable backup for apps storing sensitive data -->
<application android:allowBackup="false" ...>
```

## Runtime Integrity

`package:freerasp` detects rooted/jailbroken devices, debugger attachment, and app repackaging at runtime. This is a runtime concern outside the scope of static code review, but relevant for apps handling financial or health data.
