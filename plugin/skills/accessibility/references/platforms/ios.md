# Accessibility — iOS Platform Reference

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
| Semantics | VoiceOver rotor: every screen exposes at least one `Semantics(header: true, headingLevel: 1)` widget so users can navigate by heading | 2.4.6 AA |
| Semantics | `CupertinoSwitch`, `CupertinoSlider`, `CupertinoSegmentedControl`, `CupertinoButton` wrapped in `Semantics(label:, value:, button:)` | 4.1.2 A |
| Semantics | `liveRegion: true` paired with `SemanticsService.sendAnnouncement()` for async updates (see Flutter-Specific Gotchas below) | 4.1.3 A, 2.3.3 AAA |
| Touch | Switch Control reaches every interactive widget. `CupertinoButton` with transparent hit areas confirmed reachable | 2.1.1 A |
| Text | Run text-scaling simulation at 3x (Larger Accessibility Sizes), not 2x | 1.4.4 AA |
| Text | `MediaQuery.boldTextOf(context)` honored. No hardcoded `FontWeight.w400` on copy text | 1.4.4 AA |
| Motion | `MediaQuery.disableAnimationsOf(context)` is Android's Remove animations. iOS Reduce Motion does not set it. Gate every `AnimationController`, `AnimatedContainer`, `Hero`, `PageRouteBuilder` transition on both flags | 2.3.3 AAA |
| Motion | Flutter 3.50+: `MediaQuery.reduceMotionOf(context)` reflects Reduce Motion. Slide, scale, and parallax transitions swap to a short fade when it is `true` | 2.3.3 AAA |
| Motion | Animated images and video previews pause when `accessibilityFeatures.autoPlayAnimatedImages` or `autoPlayVideos` is `false` (Flutter 3.44+) | 2.2.2 A |
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

`Semantics(liveRegion: true)` marks a region as frequently updated but does **not automatically announce** the change on iOS (issue #45968). You must also call `SemanticsService.sendAnnouncement()`. `SemanticsService.announce()` is deprecated since Flutter 3.38, which also added `sendAnnouncement()`. Check `MediaQuery.supportsAnnounceOf(context)` first:

```dart
Semantics(
  liveRegion: true,
  child: Text('Status: $status'),
)
if (MediaQuery.supportsAnnounceOf(context)) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    'Status changed to $status',
    Directionality.of(context),
  );
}
```

Without the `sendAnnouncement()` call, VoiceOver users will not hear the update unless they manually navigate back to the live region.

### SemanticsService.sendAnnouncement() gets interrupted

When a button also has semantic hints (via `Semantics(hint:)`), calling `SemanticsService.sendAnnouncement()` during active button interaction gets interrupted (issue #122101). Debounce frequent calls and avoid calling during touch/interaction.

### Set both header and headingLevel on every heading

On iOS, only `headingLevel` makes a heading. A value above `0` adds `UIAccessibilityTraitHeader`; `header: true` alone is ignored since Flutter 3.47. The desktop embedder does the opposite and read only `header`. Write every heading as `Semantics(header: true, headingLevel: 1)` so it is a heading on every platform.

### highContrast and invertColors

These flags are reported on iOS. `highContrast` is also reported on Windows, Linux, and, since Flutter 3.47, on Android 14+. Read them through `MediaQuery`:

```dart
if (MediaQuery.highContrastOf(context)) {
  // Apply high-contrast colors
}
if (MediaQuery.invertColorsOf(context)) {
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
- [SemanticsService.sendAnnouncement API](https://api.flutter.dev/flutter/semantics/SemanticsService/sendAnnouncement.html)
- [AccessibilityFeatures class](https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures-class.html)
- [WCAG 2.2 Understanding Document](https://www.w3.org/WAI/WCAG22/Understanding/)
