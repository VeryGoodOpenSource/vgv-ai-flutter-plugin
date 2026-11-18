# Accessibility — Android Platform Reference

Per-platform WCAG 2.2 checks for Android apps using Flutter. Read this file during Phase 3 of the audit, after Phase 2 has captured Android as a selected platform.

---

## Screen Reader & Assistive Tech

- **TalkBack** — primary screen reader. Enabled at Settings > Accessibility > TalkBack.
- **Switch Access** — hardware switch or camera-based navigation. Enabled at Settings > Accessibility > Switch Access.
- **Voice Access** — voice command control.
- **Accessibility Menu** — floating simplified control panel.

**System Accessibility Settings:**
- Font scale — up to 2x (system maximum; user choice in Settings > Accessibility > Display > Font size).
- Animator duration scale — 0–10x (Settings > Developer options > Animation duration scale).
- Color inversion — inverts on-screen colors.

---

## Audit Checks

| Category | Check | WCAG 2.2 Tie-In |
| --- | --- | --- |
| Semantics | `Stack` with absolute-positioned interactive children: traversal order under TalkBack matches visual order. Wrap with `MergeSemantics` (when grouping label/value) or `Semantics(sortKey: OrdinalSortKey(...))` (when grouping is wrong) | 1.3.2 A |
| Semantics | `InkWell(onLongPress: ...)` without `onTap`: TalkBack double-tap will not activate. Add `onTap` or use a button | 4.1.2 A |
| Semantics | `Semantics(identifier: ...)` is available for UI testing (maps to Android `resource-id`, available since Flutter 3.19) | 4.1.2 A |
| Touch | Switch Access linear order respects `FocusTraversalGroup` configuration | 2.1.1 A |
| Text | Run text-scaling simulation at 2x (Android system font scale cap) | 1.4.4 AA |
| Text | Fixed-height text containers flagged: text clips at 1.5x font scale (at 2x scale it clips sooner) | 1.4.4 AA |
| Color | Color inversion compatibility: hardcoded image colors replaced with `ImageIcon(... color: Theme.of(context).iconTheme.color)` | 1.4.1 A |
| Motion | `MediaQuery.disableAnimations` reflects animator duration scale = 0. Gate every `AnimationController`, `AnimatedContainer`, `Hero`, `PageRouteBuilder` | 2.3.3 AAA |
| Focus | Focused widget never entirely hidden by sticky headers, snackbars, or overlays. Use `Scrollable.ensureVisible` | 2.4.11 AA |

---

## Testing Tools

- **Accessibility Scanner** — Google Play app. Detects missing labels, duplicate content descriptions, small targets, low contrast.
- **Android Studio "Android Ally" plugin** — live accessibility tree alongside the running app.
- **`androidTapTargetGuideline`** — Flutter test guideline. Validates 48x48 dp minimum (Android platform standard, exceeds WCAG 2.2 2.5.8 minimum of 24x24 CSS px).
- **`flutter_test` semantics helpers** — `ensureSemantics()`, `getSemantics()`, `matchesSemantics()` for verifying semantic tree structure.

---

## Flutter-Specific Gotchas

**headingLevel is binary on Android, not hierarchical**

Flutter 3.38.0 introduced a regression in heading support. The bridge switched from `Flag.IS_HEADER` to `headingLevel > 0`, breaking apps that used the old flag. The fix wires both: `result.setHeading(hasFlag(IS_HEADER) || headingLevel > 0)`.

On Android, TalkBack does **not support heading hierarchy** — only binary heading status. Use `Semantics(header: true)` or `Semantics(headingLevel: 1)` for binary heading. Do not use numeric `headingLevel` values expecting h1-h6 hierarchy on Android.

**liveRegion works reliably on Android**

`Semantics(liveRegion: true)` on Android sends an explicit `TYPE_WINDOW_CONTENT_CHANGED` event, which TalkBack respects. No additional `SemanticsService.announce()` is required (though it doesn't hurt). This differs from iOS, where `liveRegion` alone is silent.

**identifier maps to resource-id**

`SemanticsProperties.identifier` became available in Flutter 3.19 and maps to Android's `AccessibilityNodeInfo.setViewIdResourceName`. This appears as `resource-id` in UIAutomator2, useful for UI testing:

```dart
Semantics(
  identifier: 'submit-button',
  child: ElevatedButton(...),
)
```

**AccessibilityFeatures.boldText requires Android 12+**

`AccessibilityFeatures.boldText` is available only on Android API 31+ (Android 12+). Check the flag before applying:

```dart
if (MediaQuery.of(context).accessibilityFeatures.boldText) {
  // Apply bold weight
}
```

**disableAnimations has a startup bug on Android 12+**

The `disableAnimations` flag is not set until the user explicitly toggles the Reduce Motion setting (issue: not immediately available at app startup on Android 12+). Always gate animations, but be aware that on first run, animations may play even when the setting is enabled.

**TalkBack double-tap on InkWell without onTap**

`InkWell(onLongPress: ...)` without an `onTap` callback will not activate under TalkBack double-tap. TalkBack looks for `onTap` first. Either add `onTap` or use a button widget instead.

---

## Official References

- [Android Accessibility Guide](https://developer.android.com/guide/topics/ui/accessibility) — Android accessibility framework documentation
- [TalkBack User Guide](https://support.google.com/accessibility/android/answer/6283677) — TalkBack features and gestures
- [Material Design 3: Accessibility](https://m3.material.io/foundations/accessible-design/overview) — Material accessibility patterns
- [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility) — Flutter semantics and accessibility APIs
- [AccessibilityFeatures class](https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures-class.html)
- [WCAG 2.2 Understanding Document](https://www.w3.org/WAI/WCAG22/Understanding/)
