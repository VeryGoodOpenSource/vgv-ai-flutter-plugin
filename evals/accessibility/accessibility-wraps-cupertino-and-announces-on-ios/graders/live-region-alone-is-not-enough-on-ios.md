---
type: llm
---

PASS if the response states that on iOS a Semantics widget with liveRegion: true does not announce the change on its own, so SemanticsService.announce must also be called for VoiceOver to read the update.

FAIL if the response only adds liveRegion and treats that as sufficient.
