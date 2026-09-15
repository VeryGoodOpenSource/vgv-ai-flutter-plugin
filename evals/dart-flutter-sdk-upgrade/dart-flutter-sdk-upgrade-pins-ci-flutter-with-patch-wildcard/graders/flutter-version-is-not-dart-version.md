---
type: llm
---

PASS if the response never conflates the Flutter release version with the Dart SDK version. Either of these passes:

- it mentions both and keeps them as two distinct version numbers, or
- it only ever discusses the Flutter release version and says nothing about a Dart SDK version at all.

FAIL only if the response states or implies that the Flutter release version is also the Dart SDK version, or writes the Flutter release number into a slot the response itself labels as a Dart SDK version — for example a pubspec `environment: sdk:` constraint or a CI `dart_sdk:` key.

Silence about Dart is a PASS, not a FAIL. Do not require the response to mention Dart, a pubspec, or a bundled version.
