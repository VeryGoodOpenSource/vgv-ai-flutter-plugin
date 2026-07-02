---
title: "Accessibility — iOS Platform Reference"
---
<!-- GENERATED FROM skills/accessibility/references/platforms/ios.md — DO NOT EDIT. Run `npm run gen:docs` after editing the skill. -->

Per-platform WCAG 2.2 checks for iOS apps using Flutter. Read this file during Phase 3 of the audit, after Phase 2 has captured iOS as a selected platform.

---

## Screen Reader & Assistive Tech

- **VoiceOver** — primary screen reader. Enabled at Settings > Accessibility > VoiceOver.
- **Switch Control** — hardware switch navigation. Enabled at Settings > Accessibility > Switch Control.
- **Voice Control** — voice commands. Non-actionable widgets no longer get numbered labels as of Flutter 3.32.
- **AssistiveTouch** — floating menu for custom gestures.

**System Accessibility Settings:**
- Dynamic Type — font scaling up to ~3.1x (Larger Accessibility Sizes).
- Bold Text — enables bold weight on system fonts.
- Reduce Motion — disables non-essential animations and transitions.
- Reduce Transparency — replaces frosted-glass effects with opaque containers.

---

## Audit Checks

| Category | Check | WCAG 2.2 Tie-In |
| --- | --- | --- |
| Semantics | VoiceOver rotor: every screen exposes at least one `Semantics(header: true)` widget so users can navigate by heading | 2.4.6 AA |
| Semantics | `CupertinoSwitch`, `CupertinoSlider`, `CupertinoSegmentedControl`, `CupertinoButton` wrapped in `Semantics(label:, value:, button:)` | 4.1.2 A |
| Semantics | `liveRegion: true` paired with `SemanticsService.announce()` for async updates (see Flutter-Specific Gotchas below) | 4.1.3 A, 2.3.3 AAA |
| Touch | Switch Control reaches every interactive widget. `CupertinoButton` with transparent hit areas confirmed reachable | 2.1.1 A |
| Text | Run text-scaling simulation at 3x (Larger Accessibility Sizes), not 2x | 1.4.4 AA |
| Text | `MediaQuery.boldTextOverride` honored. No hardcoded `FontWeight.w400` on copy text | 1.4.4 AA |
| Motion | `MediaQuery.disableAnimations` reflects Reduce Motion. Gate every `AnimationController`, `AnimatedContainer`, `Hero`, `PageRouteBuilder` transition on this flag | 2.3.3 AAA |
| Motion | Reduce Transparency: `BackdropFilter` and frosted-glass surfaces fall back to opaque containers when Reduce Transparency is on | 1.4.11 AA |
| Focus | Focused fields near the home indicator are not occluded by `SafeArea` boundaries or the keyboard accessory | 2.4.11 AA |

---

## Testing Tools

- **Xcode Accessibility Inspector** — "Point to Inspect" for element inspection; "Run Audit" for automated issue reports. Works with iOS Simulator and physical device.
- **`iOSTapTargetGuideline`** — Flutter test guideline. Validates 44x44 pt minimum (iOS platform standard, stricter than WCAG 2.2 2.5.8 minimum of 24x24 CSS px).
- **VoiceOver Rotor** — in VoiceOver on-device, swipe up with two fingers, then swipe right to access headings list.

---

## Flutter-Specific Gotchas

### liveRegion does not auto-announce

`Semantics(liveRegion: true)` marks a region as frequently updated but does **not automatically announce** the change on iOS (issue #45968). You must also call `SemanticsService.announce()`:

```dart
Semantics(
  liveRegion: true,
  child: Text('Status: $status'),
)
SemanticsService.announce('Status changed to $status', TextDirection.ltr);
```

Without the `announce()` call, VoiceOver users will not hear the update unless they manually navigate back to the live region.

### SemanticsService.announce() gets interrupted

When a button also has semantic hints (via `Semantics(hint:)`), calling `SemanticsService.announce()` during active button interaction gets interrupted (issue #122101). Debounce frequent calls and avoid calling during touch/interaction.

### headingLevel is binary on iOS, not hierarchical

Flutter 3.38.0 wired `Semantics(headingLevel: 1)` through to iOS, but the platform does not support heading hierarchy. Use `Semantics(header: true)` for binary heading (maps to `UIAccessibilityTraitHeader`). Do not use numeric `headingLevel` values expecting h1-h6 hierarchy on iOS.

### AccessibilityFeatures.highContrast and invertColors are iOS-only

These flags exist on iOS only. Check them before applying iOS-specific UI adjustments:

```dart
final features = MediaQuery.of(context).accessibilityFeatures;
if (features.highContrast) {
  // Apply high-contrast colors
}
if (features.invertColors) {
  // Handle inverted colors
}
```

### Full Keyboard Access bug

Enabling Full Keyboard Access (external keyboard + iOS Accessibility setting) breaks external keyboard input in Flutter apps (issues #165303, #166683). This is a platform bug, not a code issue. Document this limitation in release notes if your app targets external keyboard users.

### Voice Control does not number non-actionable widgets

As of Flutter 3.32, non-actionable widgets no longer receive numbered labels under Voice Control. Only actionable widgets (buttons, text fields) get numbers. Adjust user guidance accordingly.

---

## Official References

- [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) — Apple's accessibility design principles
- [VoiceOver User Guide](https://www.apple.com/accessibility/voiceover/) — VoiceOver features and gestures
- [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility) — Flutter semantics and accessibility APIs
- [SemanticsService.announce API](https://api.flutter.dev/flutter/services/SemanticsService/announce.html)
- [AccessibilityFeatures class](https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures-class.html)
- [WCAG 2.2 Understanding Document](https://www.w3.org/WAI/WCAG22/Understanding/)
