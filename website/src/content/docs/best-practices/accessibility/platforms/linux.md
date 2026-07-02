---
title: "Accessibility — Linux Platform Reference"
---
<!-- GENERATED FROM skills/accessibility/references/platforms/linux.md — DO NOT EDIT. Run `npm run gen:docs` after editing the skill. -->

Per-platform WCAG 2.2 checks for Flutter Linux apps. Read this file during Phase 3 of the audit, after Phase 2 has captured Linux as a selected platform.

---

## Screen Reader & Assistive Tech

- **Orca** — primary screen reader for Linux. Pre-installed on many GNOME-based distributions. Available via `apt` or `dnf`.
- **Speech Dispatcher** — backend audio service for Orca.

**System Accessibility Settings:**
- Keyboard-only navigation — primary interaction modality.
- Verbosity settings — Orca verbosity can be high; avoid excessive `Semantics(label: ...)` strings.

---

## Audit Checks

| Category | Check | WCAG 2.2 Tie-In |
| --- | --- | --- |
| Semantics | Images and icons have `semanticLabel` or `Semantics(label:)` | 1.1.1 A |
| Semantics | Avoid excessive semantic labels. Orca verbosity is high by default; long or redundant labels become noisy | 4.1.2 A |
| Semantics | Form fields have associated labels via `InputDecoration(labelText:)` or explicit `Semantics(label:)` | 3.3.2 A |
| Focus | Focus indicators always visible. Desktop users navigate primarily by Tab | 2.4.7 AA |
| Focus | Focused widget never entirely hidden by sticky headers or overlays. Use `Scrollable.ensureVisible` | 2.4.11 AA |
| Keyboard | App-level `Shortcuts` widget exposing standard shortcuts (`Ctrl+K` search, `Ctrl+F` find) on screens where expected | 2.1.1 A |
| Touch | Interactive targets >= 24x24 dp (WCAG 2.2 2.5.8 AA minimum; desktop targets are often smaller than mobile) | 2.5.8 AA |

---

## Testing Tools

- **Orca** — built-in on GNOME. Toggle via Super (Windows key) + Alt + S, or via Settings > Accessibility > Screen Reader.
- **Keyboard-only testing** — use Tab, Shift+Tab, Enter, Space, arrows to navigate without a screen reader.
- **No Flutter-specific automated tooling** — manual testing with Orca is the standard approach.

---

## Flutter-Specific Gotchas

**Linux is the least mature Flutter accessibility platform**

Flutter on Linux uses GTK, which supports AT-SPI2 (Assistive Technology Service Provider Interface). However, real-world Orca compatibility has documented gaps:

- Dropdown menu content is not always readable by Orca (confirmed in Ubuntu 25.10 Flutter installer, 2025).
- Some complex widget hierarchies may not expose semantics correctly.

Treat Linux as best-effort and document known limitations.

**SemanticsRole is web-only**

`SemanticsRole` enum support is web-only in Flutter 3.32. Linux support is not confirmed. Do not rely on `SemanticsRole` for Linux accessibility.

**AccessibilityFeatures platform-specific flags not supported**

`AccessibilityFeatures` platform-specific flags (e.g., `boldText`, `highContrast`, `invertColors`) are not documented as available on Linux. Do not assume these flags work.

**Orca verbosity is high**

Orca reads out semantic labels verbosely. Avoid redundant or overly long labels. For example, instead of:

```dart
Semantics(
  label: 'Delete item button. Item name is: Item one. Press Space to activate',
  child: IconButton(...)
)
```

Use:

```dart
IconButton(
  tooltip: 'Delete item',
  onPressed: _delete,
  icon: const Icon(Icons.delete),
)
```

**Focus mode only**

Like Windows, Flutter Desktop on Linux runs in **focus mode**. Heading navigation is not available. All content must be reachable via Tab navigation.

---

## Official References

- [Orca Screen Reader](https://help.gnome.org/users/orca/stable/) — GNOME Orca documentation
- [GNOME Accessibility](https://www.gnome.org/accessibility/) — GNOME accessibility overview
- [Flutter Linux Platform Channel](https://docs.flutter.dev/platform-integration/linux) — Flutter Linux-specific documentation
- [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility) — Flutter semantics and accessibility APIs
- [AT-SPI2 Documentation](https://www.linuxfoundation.org/projects/d-bus/) — AT-SPI2 assistive technology framework
- [WCAG 2.2 Understanding Document](https://www.w3.org/WAI/WCAG22/Understanding/)
