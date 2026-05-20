# Accessibility — Audit Report Templates

Audit report templates for WCAG 2.2 conformance levels (A, AA, AA + selected AAA, AAA), with severity guide, the report template, and per-level passed-check lists. Findings reference WCAG 2.2 criterion IDs and call out the version (2.0, 2.1, or 2.2) so readers can trace the source.

---

## Severity Guide

| Severity | Meaning |
| --- | --- |
| **CRITICAL** | Blocks assistive technology users entirely. Fix before merging. |
| **MAJOR** | Significant barrier. Fix in current sprint. |
| **MINOR** | Degraded experience or polish item. Schedule for next sprint. |

Severity assignment:

- **CRITICAL**. Criterion applies at the selected level AND the issue completely blocks the use case (no semantic label on a primary action, `GestureDetector` on a required flow, focused field obscured by a sticky bar, target below 24 dp, drag-only operation with no alternative, puzzle CAPTCHA with no alternative).
- **MAJOR**. Criterion applies at the selected level AND the issue significantly degrades the experience (contrast fails by more than one point, target between 24 and 48 dp at AA, dialog does not trap focus, `Dismissible` only exposes a button after a swipe).
- **MINOR**. Criterion applies AND the issue is a refinement (contrast fails marginally, live region missing on non-critical status, focus border 1 px instead of 2 px, redundant entry on a single optional field).

---

## Report Template (all levels)

```markdown
# Flutter Accessibility Audit

**Date:** YYYY-MM-DD
**WCAG Level:** [A | AA | AA + selected AAA | AAA]
**Selected AAA criteria (if applicable):** [e.g., 1.4.6, 2.2.3, 2.4.13]
**Platforms:** [iOS | Android | Web | macOS | Windows/Linux | combination]
**Files audited:**
- path/to/file.dart

## Summary
| Severity | Count |
|----------|-------|
| CRITICAL |  0    |
| MAJOR    |  0    |
| MINOR    |  0    |

## Findings

### 1. [Short descriptive title]
- **File:** path/to/file.dart ~L42
- **WCAG:** [criterion ID] [criterion name] (Level [A/AA/AAA], WCAG [2.0/2.1/2.2])
- **Platform(s):** [iOS | Android | Web | macOS | Windows/Linux | All]
- **Severity:** [CRITICAL | MAJOR | MINOR]
- **Issue:** [description]
- **Fix:**
  // Before
  [existing code]

  // After
  [fixed code]

### 2. [Next finding...]

## Passed Checks
[copy the applicable checks from the level lists below]

## Out of Scope
[criteria the team explicitly opted out of, with rationale]
```

---

## Passed Checks — Level A

```text
- [x] A · Semantics & Screen Reader — images/icons have semantic labels; roles correct (1.1.1, 1.3.1, 4.1.2)
- [x] B · Touch Targets — interactive elements present (size assessed at AA)
- [x] C · Focus & Keyboard — all interactions keyboard-reachable; no traps (2.1.1, 2.1.2)
- [x] D · Color — color is never sole differentiator (1.4.1)
- [x] E · Text Scaling — no fixed-height text containers
- [x] F · Animation — no content flashes > 3 Hz (2.3.1)
- [x] G · Forms & Help — form errors identified in text (3.3.1); labels present (3.3.2)
- [x] H · Redundant Entry — multi-step forms reuse session data (3.3.7, WCAG 2.2)
- [x] I · Consistent Help — help mechanism placed consistently across screens (3.2.6, WCAG 2.2)
- [x] J · Status Messages — async updates announced via liveRegion or SemanticsService (4.1.3)
- [x] K · Web only — bypass blocks (2.4.1) and page titled (2.4.2) in place
```

## Passed Checks — Level AA (Level A plus these)

```text
- [x] B · Target Size Minimum — all targets >= 24x24 CSS px (2.5.8, WCAG 2.2)
- [x] B · Dragging Alternatives — every drag operation has a single-pointer alternative (2.5.7, WCAG 2.2)
- [x] C · Focus Visible — keyboard focus indicator always visible (2.4.7)
- [x] C · Focus Not Obscured (Min) — focused widget never entirely hidden by sticky/overlay content (2.4.11, WCAG 2.2)
- [x] D · Color Contrast — normal text >= 4.5:1, large text >= 3:1, UI components >= 3:1 (1.4.3, 1.4.11)
- [x] E · Text Scaling — text scales to 200% (300% on iOS) without loss (1.4.4)
- [x] F · Animation — every animation gated on disableAnimations (2.3.3 carryover)
- [x] G · Orientation — not locked to single orientation (1.3.4)
- [x] G · Input Purpose — autofillHints and keyboardType correct on personal-data fields (1.3.5)
- [x] G · Accessible Authentication (Min) — paste allowed, password managers supported, no required cognitive test without alternative (3.3.8, WCAG 2.2)
- [x] H · Reflow — content reflows at 320 CSS px equivalent (1.4.10) [Web/desktop]
- [x] H · Hover/Focus content — dismissable, hoverable, persistent (1.4.13) [Web/desktop]
```

## Passed Checks — AA + selected AAA

Use the AA list above, then append a row for each selected AAA criterion. Common opt-ins:

```text
- [x] D · Contrast Enhanced — normal text >= 7:1, large text >= 4.5:1 (1.4.6) [scoped to: <flow names>]
- [x] F · Animation from Interactions — zero motion when disableAnimations is true (2.3.3) [scoped to: <flow names>]
- [x] C · Focus Appearance — focus indicator >= 2 CSS px perimeter, 3:1 vs unfocused (2.4.13, WCAG 2.2) [scoped to: <flow names>]
- [x] J · No Timing — no time limits except for real-time events (2.2.3) [scoped to: <flow names>]
```

## Passed Checks — Level AAA (Level AA plus these)

```text
- [x] B · Target Size Enhanced — interactive elements >= 44x44 CSS px (2.5.5)
- [x] C · Keyboard (No Exception) — no GestureDetector anywhere (2.1.3)
- [x] C · Focus Not Obscured (Enhanced) — no occlusion at all (2.4.12, WCAG 2.2)
- [x] C · Focus Appearance — >= 2 CSS px perimeter, 3:1 vs unfocused (2.4.13, WCAG 2.2)
- [x] D · Contrast Enhanced — 7:1 / 4.5:1 (1.4.6)
- [x] F · Animation — zero flashing content (2.3.2)
- [x] J · No Timing — no mandatory time limits (2.2.3)
- [x] J · Timeouts — inactivity warning present (2.2.6)
- [x] K · Location — breadcrumbs or current-screen indication (2.4.8)
- [x] K · Concurrent Input — no single-modality restriction (2.5.6)
- [x] G · Accessible Authentication (Enhanced) — no required cognitive test even with alternative (3.3.9, WCAG 2.2)
- [x] G · Help — context-sensitive help available (3.3.5)
- [x] G · Error Prevention (All) — all submissions reversible or confirmable (3.3.6)
```

---

## Per-Platform Annotations on Findings

When multiple platforms are selected, every finding's Platform(s) row should be a comma-separated list. The same code path can produce different severities per platform. Example:

```markdown
### 3. SnackBar overlays focused TextField at the bottom of the form
- **File:** lib/checkout/checkout_view.dart ~L88
- **WCAG:** 2.4.11 Focus Not Obscured (Minimum) (Level AA, WCAG 2.2)
- **Platform(s):** iOS (CRITICAL), Android (CRITICAL), Web (MAJOR), macOS (MAJOR), Windows/Linux (MAJOR)
- **Severity:** CRITICAL (mobile), MAJOR (desktop, web)
- **Issue:** When the keyboard opens on iOS or Android, the SnackBar pushes up and entirely covers the focused TextField. On desktop and web the TextField stays partially visible but the SnackBar still occludes the bottom edge.
- **Fix:** [diff]
```

If a finding only applies to a subset of selected platforms, list only those platforms and add a note in the Issue field explaining which platforms were checked but not affected.
