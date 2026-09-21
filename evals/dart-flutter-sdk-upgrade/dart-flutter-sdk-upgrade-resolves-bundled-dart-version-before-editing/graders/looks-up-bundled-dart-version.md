---
type: llm
---

PASS if the response states that the Dart SDK version bundled with a Flutter release is a different version number from the Flutter release itself, and that the correct Dart version for the target Flutter release has to be looked up in Flutter's published release list or supplied by the user.

FAIL if it asserts a bundled Dart version as a remembered fact, or reuses the Flutter version as the Dart version.
