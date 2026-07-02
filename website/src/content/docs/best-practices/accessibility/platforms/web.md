---
title: "Accessibility — Web Platform Reference"
---
<!-- GENERATED FROM skills/accessibility/references/platforms/web.md — DO NOT EDIT. Run `npm run gen:docs` after editing the skill. -->

Per-platform WCAG 2.2 checks for Flutter Web apps. Read this file during Phase 3 of the audit, after Phase 2 has captured Web as a selected platform.

---

## Screen Reader & Assistive Tech

Flutter Web renders into a Semantics-mapped DOM that works with standard screen readers:

- **NVDA + Chrome** — Windows
- **JAWS + Chrome** — Windows
- **VoiceOver + Safari** — macOS
- **TalkBack + Chrome** — Android
- **VoiceOver + Safari** — iOS
- **Orca** — Linux (limited support; known gaps with dropdown menus)

**Assistive Tech Settings (browser/OS):**
- Zoom — browser text zoom and page zoom.
- Forced colors — `prefers-forced-colors` media query (Windows High Contrast Mode).
- Reduced motion — `prefers-reduced-motion` media query (added to Flutter in 2025).

---

## Audit Checks

| Category | Check | WCAG 2.2 Tie-In |
| --- | --- | --- |
| Semantics | Semantics tree enabled. Check for `SemanticsBinding.instance.ensureSemantics()` called at app startup when `kIsWeb` is true | 1.1.1 A and beyond |
| Semantics | Bypass Blocks: skip-link as a focusable `Semantics(button: true)` at the top of the document or a `<a href="#main">` injected via `js_interop` | 2.4.1 A |
| Semantics | Page Title: `<title>` updated by router-level hook or `web` package. `SystemChrome.setApplicationSwitcherDescription` does NOT update `<title>` on Web. Flag every call | 2.4.2 A |
| Semantics | Tooltips longer than 80 characters: announced verbatim via `aria-label`. Trim or move into the body | 1.1.1 A, 4.1.2 A |
| Semantics | `Image.network` carries `semanticLabel` through to the DOM. Verify with `find.bySemanticsLabel` in `flutter test` | 1.1.1 A |
| Semantics | `SemanticsRole` enum used correctly (web-only in Flutter 3.32+; do not rely on it for mobile/desktop) | 4.1.2 A |
| Touch | Target size in CSS px directly. Floor: 24x24. Flag any tappable element with measured CSS size below 24 px on either axis | 2.5.8 AA |
| Focus | Hover/focus content (tooltips, menus): dismissable (Esc), hoverable (mouse can cross to overlay), persistent (no auto-dismiss before reading) | 1.4.13 AA |
| Focus | Custom `HtmlElementView` next to focusable Flutter widgets: confirm it does not absorb keyboard events that should reach surrounding focusables | 2.1.1 A |
| Layout | Reflow at 320 CSS px. `Row` with non-`Flexible` children and fixed-width `SizedBox` siblings inside a route subtree flagged | 1.4.10 AA |
| Language | `lang` attribute on `<html>` and on inline language switches (rare, but flagged when a screen mixes languages) | 3.1.2 AA |
| Forms | Browser autofill: `autofillHints` propagates to HTML autocomplete attribute. Required for password manager support | 1.3.5 AA, 3.3.8 AA |
| Forms | `TextFormField` still has `aria-label` (issue #151929 regression in Flutter 3.22+; verify it was not removed on your version) | 1.1.1 A, 4.1.2 A |

---

## Testing Tools

- **Chrome DevTools: Elements > Accessibility tab** — inspect ARIA attributes and semantics tree.
- **Lighthouse** — built into Chrome DevTools. Runs accessibility audits.
- **Axe DevTools** — browser extension for detailed accessibility reports.
- **Flutter semantics debug mode** — `flutter run -d chrome --dart-define=FLUTTER_WEB_DEBUG_SHOW_SEMANTICS=true` overlays semantic nodes visually.
- **Standard web testing** — all standard web accessibility tools (WAVE, etc.) work against Flutter Web's `<flt-semantics>` DOM elements.

---

## Flutter-Specific Gotchas

**Semantics disabled by default**

Accessibility is **disabled by default** on Flutter Web for performance. Enable it in `main()`:

```dart
void main() {
  runApp(const MyApp());
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
}
```

Without this call, users must press an invisible button with `aria-label="Enable accessibility"` that Flutter renders. Always enable it for production.

**SemanticsRole enum is web-only**

`SemanticsRole` maps directly to ARIA roles **on web only** in Flutter 3.32+. Other platforms (mobile, desktop) do not yet support `SemanticsRole`. Do not rely on it for mobile or desktop accessibility.

Supported roles include: `tab`, `tabBar`, `tabPanel`, `dialog`, `alertDialog`, `table`, `cell`, `row`, `columnHeader`, `searchBox`, `dragHandle`, `spinButton`, `comboBox`, `menuBar`, `menu`, `menuItem`, `menuItemCheckbox`, `menuItemRadio`, `list`, `listItem`, `form`, `tooltip`, `loadingSpinner`, `progressBar`, `hotKey`, `radioGroup`, `status`, `alert`, `complementary`, `contentInfo`, `main`, `navigation`, `region`.

**aria-label removed from input elements (regression)**

A known bug in Flutter 3.22+ removed `aria-label` from `<input>` semantic elements, breaking `TextFormField` accessibility on web (issue #151929). Check your Flutter version. If affected, apply a workaround or upgrade.

**headingLevel fully wired on web**

`Semantics(headingLevel: 1)` through `headingLevel: 6` maps to `<h1>` through `<h6>` (or `aria-level` on generic elements). Heading hierarchy works on web, unlike iOS and Android where it's binary.

**AccessibilityFeatures.reduceMotion added in 2025**

Web support for `prefers-reduced-motion` media query was added recently (PR #180041, 2025). Check the Flutter version to ensure the flag is available.

**identifier maps to flt-semantics-identifier attribute**

`SemanticsProperties.identifier` maps to a `flt-semantics-identifier` DOM attribute (not a standard ARIA property). Use for custom testing, not for accessibility trees.

**scopesRoute + namesRoute requires careful ARIA wiring**

When `scopesRoute` and `namesRoute` are on separate nodes (not the same node), the ARIA strategy differs from when combined (issue #126030). Test thoroughly and refer to the issue for workarounds.

---

## Official References

- [Flutter Web Accessibility Guide](https://docs.flutter.dev/ui/accessibility/web-accessibility) — Flutter's web-specific accessibility docs
- [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility) — core Flutter semantics and accessibility APIs
- [ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/) — ARIA roles, states, and properties
- [WebAIM Screen Reader Testing](https://webaim.org/articles/screenreader_testing/) — screen reader testing methodology
- [Chrome Accessibility Audit Documentation](https://developer.chrome.com/docs/lighthouse/accessibility/) — Lighthouse audit details
- [SemanticsRole enum](https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html)
- [WCAG 2.2 Understanding Document](https://www.w3.org/WAI/WCAG22/Understanding/)
