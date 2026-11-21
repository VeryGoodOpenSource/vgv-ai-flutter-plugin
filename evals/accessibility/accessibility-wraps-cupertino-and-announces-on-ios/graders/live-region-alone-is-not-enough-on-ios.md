---
type: llm
---

PASS if the response states that on iOS a Semantics widget with liveRegion: true does not announce the change on its own, so SemanticsService.sendAnnouncement must also be called for VoiceOver to read the update.

FAIL if the response calls the deprecated SemanticsService.announce instead of SemanticsService.sendAnnouncement.

FAIL if the response only adds liveRegion and treats that as sufficient.
