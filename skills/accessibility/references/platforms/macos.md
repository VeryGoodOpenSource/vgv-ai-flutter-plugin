# Accessibility — macOS Platform Reference

Per-platform WCAG 2.2 checks for Flutter macOS apps. Read this file during Phase 3 of the audit, after Phase 2 has captured macOS as a selected platform.

---

## Screen Reader & Assistive Tech

- **VoiceOver** — primary screen reader. Toggle with Cmd+F5.
- **Full Keyboard Access** — enable keyboard navigation in System Preferences > Keyboard > Shortcuts. Toggle with Ctrl+F7.

**System Accessibility Settings:**

- Reduce Motion — disables non-essential animations and transitions.
- Increase Contrast — increases contrast on system UI and colors.

---

## Audit Checks

| Category | Check | WCAG 2.2 Tie-In |
| --- | --- | --- |
| Focus | All focusables have a visible focus indicator that satisfies 2.4.7 AA. Assume Full Keyboard Access is off by default but design as if it is on | 2.4.7 AA |
| Focus | Focus indicator inside dialogs: visible regardless of Full Keyboard Access state, since VoiceOver users without FKA still rely on it for sighted navigation | 2.4.7 AA, 2.4.13 AAA |
| Focus | Focused widget never entirely hidden by sticky headers, snackbars, or overlays. Use `Scrollable.ensureVisible` | 2.4.11 AA |
| Color | `MediaQuery.highContrast` reflects macOS Increase Contrast. Hardcoded `Color(0xff...)` outside `ThemeExtension` flagged | 1.4.11 AA |
| Motion | `MediaQuery.disableAnimations` reflects Reduce Motion. Gate every `AnimationController`, `AnimatedContainer`, `Hero`, `PageRouteBuilder` | 2.3.3 AAA |
| Semantics | macOS VoiceOver is keyboard-driven (VO + arrows, VO + space). The `Semantics` tree exposed is the same as iOS, but report copy notes traversal is keyboard, not swipe | 1.3.2 A |
| Semantics | Images and icons have `semanticLabel` or `Semantics(label:)` | 1.1.1 A |
| Keyboard | App-level `Shortcuts` widget exposing standard macOS shortcuts (`Cmd+K` search, `Cmd+,` settings) on screens where expected | 2.1.1 A |

---

## Testing Tools

- **Xcode Accessibility Inspector** — works for macOS apps in addition to iOS Simulator. "Point to Inspect" and "Run Audit" features available.
- **VoiceOver on Device** — press Cmd+F5 to enable and test with physical macOS or simulator.
- **Focus debugging** — use `showFocusHighlight: true` in `MaterialApp` or `CupertinoApp` during development to visualize focus bounds.

---

## Flutter-Specific Gotchas

**AccessibilityFeatures.highContrast is iOS-only**

`AccessibilityFeatures.highContrast` does **not exist on macOS**. Detect macOS Increase Contrast via `MediaQuery.platformBrightness` or supply separate `MaterialApp.highContrastTheme`:

```dart
final isHighContrast = MediaQuery.of(context).highContrast;
if (isHighContrast) {
  // Apply high-contrast theme
}
```

### VoiceOver is keyboard-driven, not swipe-based

macOS VoiceOver uses keyboard commands (VO + arrows, VO + space) to navigate, unlike iOS VoiceOver which uses swipes. Screen readers speak semantics the same way, but the modality is different. Test with actual keyboard commands, not swipes.

**SemanticsRole is web-only**

`SemanticsRole` enum support is web-only in Flutter 3.32. macOS support is planned but not yet shipped. Do not rely on `SemanticsRole` for macOS accessibility.

**Focus indicator visibility is critical**

Since Full Keyboard Access is off by default but users can enable it, always provide a visible focus indicator on all focusable widgets. Users without Full Keyboard Access enabled may still use keyboard navigation with assistive tech.

---

## Official References

- [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) — Apple's accessibility design principles
- [VoiceOver User Guide](https://www.apple.com/accessibility/voiceover/) — VoiceOver features and keyboard commands
- [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility) — Flutter semantics and accessibility APIs
- [Flutter macOS Platform Channel](https://docs.flutter.dev/platform-integration/macos) — Flutter macOS-specific documentation
- [AccessibilityFeatures class](https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures-class.html)
- [WCAG 2.2 Understanding Document](https://www.w3.org/WAI/WCAG22/Understanding/)
