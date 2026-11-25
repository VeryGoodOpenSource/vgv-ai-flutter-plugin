# Accessibility — Linux Platform Reference

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

**What Orca gets from Flutter on Linux**

Flutter 3.50 exposes an ATK tree to Orca through AT-SPI2. Supported: labels, focus, every semantics action (tap, focus, expand, collapse), text field values, and the checked, selected, focused, enabled and read-only states. Not supported:

- Expanded and collapsed state. Orca never hears whether a dropdown or expansion tile is open.
- Heading levels. Headings come from `header: true` and have no level.
- Slider values. Sliders are not exposed as an ATK value.
- Hints, tooltips and custom semantics actions.
- Reading non-focusable content without moving focus to it.

Report these as platform limitations in a Linux audit, not as app defects.

**SemanticsRole is ignored on Linux**

In Flutter 3.50, the Linux embedder does not read `SemanticsRole`. ATK roles come only from semantics flags: `button`, `checked` (checkbox, or radio button with `inMutuallyExclusiveGroup`), `toggled`, `slider`, `textField` (password text when `obscured`), `header`, `link` and `image`. Every other node is `ATK_ROLE_PANEL`. Set the flag, not `role`, to give a widget its role here.

**Only highContrast and disableAnimations reach MediaQuery on Linux**

The Linux embedder sends two accessibility features. `MediaQuery.highContrastOf(context)` follows the GNOME high-contrast setting. `MediaQuery.disableAnimationsOf(context)` is `true` when GNOME animations are off. `boldText`, `invertColors`, `reduceMotion` and `accessibleNavigation` are always `false` on Linux.

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
