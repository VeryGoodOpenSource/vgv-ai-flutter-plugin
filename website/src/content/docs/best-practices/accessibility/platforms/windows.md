---
title: "Accessibility — Windows Platform Reference"
---
<!-- GENERATED FROM skills/accessibility/references/platforms/windows.md — DO NOT EDIT. Run `npm run gen:docs` after editing the skill. -->

Per-platform WCAG 2.2 checks for Flutter Windows apps. Read this file during Phase 3 of the audit, after Phase 2 has captured Windows as a selected platform.

---

## Screen Reader & Assistive Tech

- **Narrator** — built-in screen reader. Activated via Windows+Enter.
- **NVDA** — recommended free screen reader for testing. Download from [NVDA](https://www.nvaccess.org/)
- **JAWS** — commercial screen reader.

**System Accessibility Settings:**

- Windows High Contrast Mode — forces a specific color palette (Black, White, or other presets). Controlled via Settings > Ease of Access > Display > High Contrast.
- Keyboard-only navigation — primary interaction modality for assistive tech users.

---

## Audit Checks

| Category | Check | WCAG 2.2 Tie-In |
| --- | --- | --- |
| Semantics | NVDA browse mode vs focus mode: Flutter Desktop on Windows runs in **focus mode only**. Screens that rely on heading navigation as the primary discovery pattern must note this limitation | 1.3.2 A, 2.4.6 AA |
| Semantics | Images and icons have `semanticLabel` or `Semantics(label:)` | 1.1.1 A |
| Semantics | Form fields have associated labels via `InputDecoration(labelText:)` or explicit `Semantics(label:)` | 3.3.2 A |
| Color | Windows High Contrast Mode: hardcoded `Color(0xff...)` outside `ThemeExtension` flagged. Prefer `Theme.of(context).colorScheme` tokens that respond to `MediaQuery.highContrast` | 1.4.11 AA |
| Focus | Focus indicators always visible. Desktop users navigate primarily by Tab | 2.4.7 AA |
| Focus | Focused widget never entirely hidden by sticky headers or overlays. Use `Scrollable.ensureVisible` | 2.4.11 AA |
| Focus | Focus appearance (2.4.13 AAA scoped audits): indicator >= 2 CSS px perimeter, 3:1 contrast vs unfocused state | 2.4.13 AAA |
| Keyboard | App-level `Shortcuts` widget exposing `Ctrl+K` (search), `Ctrl+F` (find), `Ctrl+,` (settings) on screens where expected | 2.1.1 A |
| Touch | Interactive targets >= 24x24 dp (WCAG 2.2 2.5.8 AA minimum; desktop targets are often smaller than mobile) | 2.5.8 AA |

---

## Testing Tools

- **Narrator** — built-in, but limited. Good for quick testing. Activated via Windows+Enter.
- **NVDA** — recommended for thorough testing. Open-source, free, actively maintained. Download from [NVDA](https://www.nvaccess.org/)
- **JAWS** — commercial option. Trial available.
- **Inspect** — Windows SDK tool for inspecting UIA (UI Automation) element trees. Help understand how Flutter elements are exposed to assistive tech.
- **Keyboard-only testing** — use Tab, Shift+Tab, Enter, Space, arrows to navigate without a screen reader.

---

## Flutter-Specific Gotchas

### AccessibilityFeatures.highContrast is iOS-only

`AccessibilityFeatures.highContrast` does **not exist on Windows**. Detect Windows High Contrast Mode via `ThemeData(useSystemColors: true)`:

```dart
ThemeData(
  useMaterial3: true,
  useSystemColors: true, // Auto-applies Windows High Contrast
)
```

However, support for Windows forced-colors mode is incomplete (issue #75883). Always test with High Contrast enabled in Windows Settings.

### Focus mode only, no browse mode

Flutter Desktop on Windows runs in UIA **focus mode only** — unlike web where NVDA browse mode lets users skim content by headings. Screens that rely on heading navigation as the primary discovery pattern should note this limitation in findings. All content must be reachable via Tab navigation.

### SemanticsRole is web-only

`SemanticsRole` enum support is web-only in Flutter 3.32. Windows support is planned but not yet shipped. Do not rely on `SemanticsRole` for Windows accessibility.

### UIA element tree mapping

Flutter Windows uses the UIA (UI Automation) accessibility API. The semantics tree maps to UIA automation elements. Use Inspect tool to verify correct element types and properties.

### Keyboard is the primary interaction

On Windows desktop, keyboard navigation is the primary interaction pattern. Every interactive element must be reachable via Tab and activatable via Enter or Space. Test thoroughly with keyboard-only navigation.

---

## Official References

- [Windows Accessibility](https://support.microsoft.com/en-us/accessibility) — Microsoft's accessibility overview
- [NVDA Documentation](https://www.nvaccess.org/download/) — free screen reader documentation
- [Flutter Windows Platform Channel](https://docs.flutter.dev/platform-integration/windows) — Flutter Windows-specific documentation
- [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility) — Flutter semantics and accessibility APIs
- [UI Automation Documentation](https://learn.microsoft.com/en-us/windows/win32/winauto/entry-uiauto-win32) — Microsoft UIA framework
- [Inspect Tool Documentation](https://learn.microsoft.com/en-us/windows/win32/winauto/inspect-objects) — using Inspect to debug accessibility
- [WCAG 2.2 Understanding Document](https://www.w3.org/WAI/WCAG22/Understanding/)
