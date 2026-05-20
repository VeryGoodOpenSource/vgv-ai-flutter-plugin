# Accessibility — Platform Matrix

Per-platform check tables for the five platforms the skill supports: iOS, Android, Web, macOS, Windows/Linux desktop. Read this file during Phase 3 of the audit, after Phase 2 has captured the platform selection.

Every row of the universal six-category audit (semantics, touch targets and dragging, focus and keyboard, color contrast, text scaling, animation) plus the new seventh category (forms, authentication, help) needs a platform-aware lens. The tables below list the additional checks that fire per platform, on top of the universal rules in `SKILL.md`.

---

## iOS

Assistive tech: VoiceOver, Switch Control, Voice Control. System settings: Dynamic Type (up to ~3.1x), Bold Text, Reduce Motion, Reduce Transparency.

| Category | Check | WCAG Tie-In |
| --- | --- | --- |
| Semantics | VoiceOver rotor: every screen exposes at least one `Semantics(header: true)` widget so users can navigate by heading | 2.4.6 AA |
| Semantics | `CupertinoSwitch`, `CupertinoSlider`, `CupertinoSegmentedControl`, `CupertinoButton` wrapped in `Semantics(label:, value:, button:)` | 4.1.2 A |
| Touch | Switch Control reaches every interactive widget. `CupertinoButton` with transparent hit areas confirmed reachable | 2.1.1 A |
| Text | Run text-scaling simulation at 3x (Larger Accessibility Sizes), not 2x | 1.4.4 AA |
| Text | `MediaQuery.boldTextOverride` honored. No hardcoded `FontWeight.w400` on copy text | 1.4.4 AA |
| Motion | `MediaQuery.disableAnimations` reflects Reduce Motion. Already covered by the universal rule | 2.3.3 AAA |
| Motion | Reduce Transparency: `BackdropFilter` and frosted-glass surfaces fall back to opaque containers when Reduce Transparency is on | 1.4.11 AA |
| Focus | Focused fields near the home indicator are not occluded by `SafeArea` boundaries or the keyboard accessory | 2.4.11 AA (WCAG 2.2) |

---

## Android

Assistive tech: TalkBack, Switch Access, Voice Access. System settings: font scale (up to 2x), animator duration scale, color inversion.

| Category | Check | WCAG Tie-In |
| --- | --- | --- |
| Semantics | `Stack` with absolute-positioned interactive children: traversal order under TalkBack matches visual order. Wrap with `MergeSemantics` (when grouping label/value) or `Semantics(sortKey: OrdinalSortKey(...))` (when grouping is wrong) | 1.3.2 A |
| Semantics | `InkWell(onLongPress: ...)` without `onTap`: TalkBack double-tap will not activate. Add `onTap` or use a button | 4.1.2 A |
| Touch | Switch Access linear order respects `FocusTraversalGroup` configuration. `Wrap` with reversed `Direction` flagged | 2.1.1 A |
| Text | Run text-scaling simulation at 2x (Android system font scale cap) | 1.4.4 AA |
| Color | Color inversion compatibility: hardcoded image colors replaced with `ImageIcon(... color: Theme.of(context).iconTheme.color)` | 1.4.1 A |
| Motion | `MediaQuery.disableAnimations` reflects animator duration scale = 0. Already covered by the universal rule | 2.3.3 AAA |

---

## Web

Flutter Web renders into a Semantics-mapped DOM. Most platform-specific gotchas live here.

| Category | Check | WCAG Tie-In |
| --- | --- | --- |
| Semantics | Semantics tree enabled. Grep for `RuntimeError.semanticsEnabled = false` and any custom embedder that disables it | 1.1.1 A and beyond |
| Semantics | Bypass Blocks: skip-link as a focusable `Semantics(button: true)` at the top of the document or a `<a href="#main">` injected via `js_interop` | 2.4.1 A |
| Semantics | Page Title: `<title>` updated by router-level hook or `web` package. `SystemChrome.setApplicationSwitcherDescription` does NOT update `<title>` on Web. Flag every call | 2.4.2 A |
| Semantics | Tooltips longer than 80 characters: announced verbatim via `aria-label`. Trim or move into the body | 1.1.1 A and 4.1.2 A |
| Semantics | `Image.network` carries `semanticLabel` through to the DOM. Verify with `find.bySemanticsLabel` in `flutter test` | 1.1.1 A |
| Touch | 2.5.8 measured in CSS px directly. Floor: 24x24. Flag any tappable element with measured CSS size below 24 px on either axis | 2.5.8 AA (WCAG 2.2) |
| Focus | Hover/focus content (tooltips, menus): dismissable (Esc), hoverable (mouse can cross to overlay), persistent (no auto-dismiss before reading) | 1.4.13 AA |
| Focus | Custom `HtmlElementView` next to focusable Flutter widgets: confirm it does not absorb keyboard events that should reach surrounding focusables | 2.1.1 A |
| Layout | Reflow at 320 CSS px. `Row` with non-`Flexible` children and fixed-width `SizedBox` siblings inside a route subtree flagged | 1.4.10 AA |
| Language | `lang` attribute on `<html>` and on inline language switches (rare, but flagged when a screen mixes languages) | 3.1.2 AA |
| Forms | Browser autofill: `autofillHints` propagates to HTML autocomplete attribute. Required for password manager support (3.3.8) | 1.3.5 AA, 3.3.8 AA (WCAG 2.2) |

---

## macOS

Assistive tech: VoiceOver, Full Keyboard Access (FKA, off by default). System settings: Reduce Motion, Increase Contrast.

| Category | Check | WCAG Tie-In |
| --- | --- | --- |
| Focus | All focusables have a visible focus indicator that satisfies 2.4.7 AA. Assume FKA is off by default but design as if it is on | 2.4.7 AA |
| Focus | Focus indicator inside dialogs: visible regardless of FKA state, since VoiceOver users without FKA still rely on it | 2.4.7 AA, 2.4.13 AAA (WCAG 2.2) |
| Color | `MediaQuery.highContrast` reflects macOS Increase Contrast. Hardcoded `Color(0xff...)` outside `ThemeExtension` flagged | 1.4.11 AA |
| Motion | `MediaQuery.disableAnimations` reflects Reduce Motion. Same rule as iOS | 2.3.3 AAA |
| Semantics | macOS VoiceOver is keyboard-driven (VO + arrows, VO + space). The `Semantics` tree exposed is the same as iOS, but report copy notes traversal is keyboard, not swipe | 1.3.2 A |

---

## Windows / Linux desktop

Assistive tech: Narrator, NVDA, JAWS (Windows), Orca (Linux). System settings: Windows High Contrast Mode (Windows-only), keyboard shortcuts.

| Category | Check | WCAG Tie-In |
| --- | --- | --- |
| Semantics | NVDA browse mode vs focus mode: Flutter Desktop on Windows runs in focus mode only. Screens that rely on heading navigation as the primary discovery pattern flagged with a "won't work the same as web" finding | 1.3.2 A, 2.4.6 AA |
| Color | Windows High Contrast Mode: hardcoded `Color(0xff...)` outside `ThemeExtension` flagged. Prefer `Theme.of(context).colorScheme` tokens that respond to `MediaQuery.highContrast` | 1.4.11 AA |
| Semantics | Linux (Orca): treat the same as Windows for focus and labels. Note Orca's verbosity defaults are higher, so excessive `Semantics(label: ...)` strings get noisy | 4.1.2 A |
| Focus | Focus indicators: always visible. Desktop users navigate primarily by Tab | 2.4.7 AA |
| Keyboard | App-level `Shortcuts` widget exposing `Ctrl+K`, `Ctrl+F`, `Ctrl+,` etc. for search, find, settings on screens where these are expected | 2.1.1 A |

---

## Cross-Platform Severity Adjustments

The same code path can produce different severities per platform. Use this table to decide how to assign severity per platform when listing a finding.

| Issue | iOS | Android | Web | macOS | Win/Linux |
| --- | --- | --- | --- | --- | --- |
| `GestureDetector` for tap | CRITICAL | CRITICAL | CRITICAL | CRITICAL | CRITICAL |
| 16x16 target (below 24 dp) | CRITICAL | CRITICAL | CRITICAL | MAJOR | MAJOR |
| 36 dp target (between 24 and 48 dp) | MAJOR | MAJOR | MAJOR | MINOR | MINOR |
| `Dismissible` without delete button | CRITICAL | CRITICAL | MAJOR | MAJOR | MAJOR |
| Focused field obscured by sticky bottom bar | CRITICAL | CRITICAL | MAJOR | MAJOR | MAJOR |
| `AnimatedContainer` ignoring disableAnimations | MAJOR | MAJOR | MAJOR | MAJOR | MAJOR |
| Tooltip > 80 chars | MINOR | MINOR | MAJOR | MINOR | MINOR |
| `setApplicationSwitcherDescription` for page title | n/a | n/a | CRITICAL | n/a | n/a |
| Bypass blocks missing | n/a | n/a | MAJOR | n/a | n/a |
| Cupertino widget without semantic wrapper | MAJOR | MINOR | MINOR | MAJOR | MINOR |
| Hardcoded Color outside ThemeExtension | MINOR | MINOR | MINOR | MAJOR | MAJOR (Windows HCM) |

Severities in this table assume the criterion is active at the selected level. Findings for criteria above the selected level (for example, AAA criteria when AA is selected) are dropped from the report unless the criterion is in the user's "selected AAA" list from Phase 1.
