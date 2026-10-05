---
name: accessibility
description: >
  Audits or remediates Flutter widgets against WCAG 2.2 conformance levels A, AA, or AAA
  across iOS, Android, Web, macOS, Windows, and Linux, covering Semantics labels and screen
  reader output under VoiceOver and TalkBack, touch target sizes, dragging alternatives, focus
  order and keyboard navigation, color contrast, text scaling, animation gating on
  disableAnimations, and form autofillHints, including the test suite that locks every fix in.
  Use when building, auditing, or reviewing Flutter widgets for accessibility on one or
  several of those platforms.
effort: medium
argument-hint: "[wcag-level] [platform...]"
allowed-tools: Read Glob Grep
---

# Accessibility

Flutter accessibility auditing and remediation across WCAG 2.2 conformance levels A, AA, and
AAA. This file is the workflow; the reference files listed under **Additional Resources** are
loaded on demand, and each phase below names the one it needs.

Load only the file the current phase names.

---

## Core Standards

Apply these standards to all accessibility work:

**Conformance Level** — Begin every audit by asking which WCAG 2.2 conformance level the project targets (A, AA, AA + selected AAA, or AAA). Never assume AA.

**Platform Selection** — Begin every audit by asking which of the six platforms are targeted (iOS, Android, Web, macOS, Windows, Linux). Apply the platform rules from the matching file(s) in `references/platforms/`.

**Image Semantics** (WCAG 1.1.1) — Every `Image` must have `semanticLabel`, or be wrapped in `Semantics(label:)`. Decorative images use `excludeFromSemantics: true`.

**Gesture Detector** (WCAG 2.1.1) — Never use bare `GestureDetector` for tap targets. Use `InkWell`, `ElevatedButton`, `TextButton`, or `IconButton`. `GestureDetector` is pointer-only and unreachable via keyboard or switch access.

**Target Size** (WCAG 2.5.8) — Target Size Minimum is 24x24 CSS px (≈ 24 dp) at AA. The VGV recommended minimum is 48x48 dp. Findings between 24 dp and 48 dp are flagged as VGV-style at AA, and as WCAG findings at AAA via 2.5.5 (44 dp).

**Drag Alternatives** (WCAG 2.5.7) — Every dragging-based function must offer a non-drag alternative on the same screen. Sliders need keyboard or stepper alternatives. `Dismissible` needs an explicit delete button. `ReorderableListView` needs up/down or "move to" controls.

**Focus Not Obscured** (WCAG 2.4.11) — A focused widget must not be entirely obscured by sticky headers, snackbars, bottom sheets, persistent FABs, or overlays. Use `Scrollable.ensureVisible` and `Scaffold.resizeToAvoidBottomInset: true`.

**Color Differentiation** (WCAG 1.4.1) — Never use color as the sole differentiator. Always pair color with a label, icon, or shape.

**Animation and Motion** (WCAG 2.3.3) — All animations must respect `MediaQuery.disableAnimations`. Gate every `AnimationController`, `AnimatedContainer`, `Hero` transition, and `PageRouteBuilder` transition on this flag.

**Icon Buttons** (WCAG 4.1.2) — Icon-only buttons must have a `Tooltip` or `Semantics(label:)`. Screen readers have no other way to convey purpose.

**Exclude Semantics** (WCAG 1.1.1) — Never use `ExcludeSemantics` on non-decorative content. It strips its whole subtree from the semantics tree, so any button or other control inside it disappears from TalkBack and VoiceOver and its action becomes unreachable for screen reader users. State that consequence when declining a request to wrap actionable content. To stop a screen reader from stopping on every child, use `MergeSemantics` around the static label and value pair only, leaving interactive siblings outside it so they stay independently focusable.

**Text Containers** (WCAG 1.4.4) — Fixed-height containers must not wrap `Text`. Use `minHeight` constraints. Fixed heights clip text at 1.5x font scale on Android, sooner on iOS where Larger Accessibility Sizes go to ~3.1x.

**Contrast** (WCAG 1.4.3) — All text and UI components must meet the contrast ratio for the selected WCAG level. See [`references/wcag-criteria.md`](references/wcag-criteria.md).

**Cupertino Semantics** (WCAG 4.1.2) — Cupertino widgets (`CupertinoSwitch`, `CupertinoSlider`, `CupertinoSegmentedControl`, `CupertinoButton`) ship with weaker semantic defaults than their Material equivalents. Always wrap them in `Semantics(label:, value:, button:)`.

**Autofill Hints** (WCAG 1.3.5) — Every `TextField` collecting structured personal data (email, username, password, name, address, phone, oneTimeCode) must declare `autofillHints`. Required for 1.3.5 at AA and the foundation for 3.3.7 Redundant Entry at A.

**Finding Format** — Every audit finding carries the WCAG criterion ID together with that criterion's name (`2.5.8 Target Size (Minimum)`, never a bare `2.5.8`), a severity of exactly CRITICAL, MAJOR, or MINOR in upper case, and the fix as before-and-after Dart code. Never grade severity as High/Medium/Low or Serious/Moderate/Minor. Never ship a finding whose fix is prose only.

**Async Announcements** (WCAG 4.1.3) — Every async user-visible state change must announce itself via `Semantics(liveRegion: true)` or `SemanticsService.announce`.

---

## Workflow

Every accessibility engagement follows four phases in sequence. Do not skip Phase 1 or Phase 2.

> **Cross-harness note.** Phases 1, 2, and 4 below use `AskUserQuestion`. On a host without it, invoke whatever equivalent user-question tool the host provides; if it has none, ask the same question as plain numbered text. Either way, wait for the reply before proceeding.

### Phase 1: Conformance Level Selection

Use `AskUserQuestion` to ask:

```yaml
question: "Which WCAG 2.2 conformance level are you targeting?"
header: "WCAG level"
options:
  - label: "A"
    description: "Removes the most critical barriers. Includes the new 2.2 criteria 3.2.6 Consistent Help and 3.3.7 Redundant Entry."
  - label: "AA"
    description: "Standard most regulators require. Adds contrast, resize text, focus visible, plus the four new 2.2 AA criteria: 2.4.11, 2.5.7, 2.5.8, 3.3.8."
  - label: "AA + selected AAA"
    description: "AA across the app, plus specific AAA criteria scoped to flagged flows. Common: 1.4.6 enhanced contrast, 2.2.3 no timing, 2.4.13 focus appearance."
  - label: "AAA"
    description: "Full AAA. 7:1 contrast, no timing, no exceptions to keyboard. Rare for whole products."
```

If the user picks "AA + selected AAA", follow up with a free-text request for the AAA criterion IDs they want included (for example, "1.4.6, 2.2.3, 2.4.13").

**Outcome:** Record the selected level. All audit checks, criterion citations, and fix recommendations apply only the rules for that level (plus all levels below it) and any opted-in AAA criteria.

### Phase 2: Platform Selection

Use `AskUserQuestion` (multi-select if available, otherwise one question with a comma-separated reply) to ask:

```yaml
question: "Which platforms is this app targeting? Select all that apply."
header: "Platforms"
options:
  - label: "iOS"
    description: "VoiceOver, Switch Control, Dynamic Type up to 3.1x, Voice Control, Bold Text, Reduce Motion, Reduce Transparency."
  - label: "Android"
    description: "TalkBack, Switch Access, font scale up to 2x, Voice Access, color inversion."
  - label: "Web"
    description: "Flutter Web rendered to a Semantics-mapped DOM. NVDA + Chrome, JAWS + Chrome, VoiceOver + Safari."
  - label: "macOS"
    description: "VoiceOver, Full Keyboard Access, Reduce Motion, Increase Contrast."
  - label: "Windows / Linux desktop"
    description: "Narrator, NVDA, JAWS (Windows), Orca (Linux), Windows High Contrast Mode."
```

**Outcome:** Record the selected platforms. Load the matching file(s) from `references/platforms/` (for example, `references/platforms/ios.md` for iOS, `references/platforms/android.md` for Android). Load only the files for platforms that were selected; do not load unnecessary files.

### Phase 3: Level-Appropriate, Platform-Aware Audit

For each selected platform, audit the provided files or widgets across seven categories, in order:

1. **Semantics and Screen Reader** — Labels, roles, live regions, merge/exclude correctness, Cupertino semantic gaps, reading order under TalkBack and VoiceOver.

2. **Touch Targets and Dragging Alternatives** — WCAG 2.2 2.5.8 minimum (24 CSS px) at AA, 2.5.5 enhanced (44 CSS px) at AAA, VGV recommended 48 dp, plus 2.5.7 dragging alternatives.

3. **Focus and Keyboard Navigation** — Operability, traversal order, dialog focus trapping, focus indicators, plus 2.4.11 / 2.4.12 focus-not-obscured.

4. **Color Contrast** — Text and UI component ratios at the selected level's threshold (table below).

5. **Text Scaling** — No fixed-height text containers, no clamped text scaling. Cap simulations at 2x on Android and Web, 3x on iOS.

6. **Animation and Motion** — `disableAnimations` gating across `AnimationController`, `Hero`, `AnimatedContainer`, `PageRouteBuilder`. No content flashing above 3 Hz at AA, zero flashing at AAA.

7. **Forms, Authentication, and Help** — `autofillHints` (1.3.5, 3.3.7), accessible authentication (3.3.8 / 3.3.9), consistent placement of help mechanisms (3.2.6).

Apply only criteria active at the selected level (plus opted-in AAA) and relevant to the selected platforms.

Write every finding in this block, with no row omitted:

````markdown
### 1. Close button is a 16x16 GestureDetector
- **File:** lib/order/order_summary.dart ~L26
- **WCAG:** 2.1.1 Keyboard (Level A, WCAG 2.0)
- **Platform(s):** iOS, Android
- **Severity:** CRITICAL
- **Issue:** `GestureDetector` is pointer-only, so the close action is unreachable via VoiceOver, TalkBack, Switch Control, and Switch Access. Expected: a focusable, activatable button with an accessible name.
- **Fix:**

```dart
// Before
SizedBox(
  width: 16,
  height: 16,
  child: GestureDetector(
    onTap: onClose,
    child: const Icon(Icons.close, size: 16),
  ),
)
```

```dart
// After
IconButton(
  onPressed: onClose,
  tooltip: 'Close order summary',
  iconSize: 24,
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
  icon: const Icon(Icons.close),
)
```
````

Rules that hold for every finding in the report, MINOR ones included:

- **Criterion.** Write the ID and the criterion's name together, then the level and the WCAG version: `2.5.8 Target Size (Minimum) (Level AA, WCAG 2.2)`. A bare number is an incomplete finding.
- **Severity.** Exactly one of CRITICAL, MAJOR, MINOR, taken from the severity guide in [`references/audit-templates.md`](references/audit-templates.md). When platforms differ, keep those three labels and qualify them: `CRITICAL (iOS, Android), MAJOR (Web)`.
- **Fix.** Always a Before block and an After block of real Dart, side by side under that finding. Prose advice alone is not a fix, and neither is an After block on its own — the reader has to see the exact code being replaced. One consolidated corrected widget at the end of the report does not satisfy this for the findings above it.
- **Scope.** If a check raises a concern you cannot resolve from the code alone (contrast without colors, reading order without a running app), state it under Out of Scope, not as a finding. A finding is something you can cite, grade, and fix.

**Outcome:** After completing all seven categories, produce the Audit Report using the template in [`references/audit-templates.md`](references/audit-templates.md). Pick the level-specific passed-check list that matches Phase 1.

### Phase 4: Remediation Scope Selection

After delivering the report, use `AskUserQuestion`:

```yaml
question: "The audit is complete. How would you like to proceed with fixes?"
header: "Fix scope"
options:
  - label: "All issues"
    description: "Fix every CRITICAL, MAJOR, and MINOR finding"
  - label: "Critical + Major only"
    description: "Fix blockers and significant barriers; skip MINOR polish items"
  - label: "Critical only"
    description: "Fix only what blocks assistive technology users entirely"
  - label: "Specific findings"
    description: "List the finding numbers you want fixed"
```

**Outcome:** Apply exactly the fixes the user selects. After applying fixes, confirm: "Fixed [N] findings ([severities]). [N remaining] remain open."

Write tests covering every fix so it cannot regress. See [`references/testing.md`](references/testing.md) for a suite spanning all seven audit categories, and [`references/widget-mapping.md`](references/widget-mapping.md) when the correct implementation for a specific widget is unclear.

---

## WCAG 2.2 Level Criteria Reference

The per-level criterion tables (A, AA, AAA) with the Flutter check for each live in [`references/wcag-criteria.md`](references/wcag-criteria.md). Load it in Phase 3 to pick the criteria active at the selected level.

---

## Quick Anti-Pattern Reference

Full code samples and corrected versions live in [`references/examples.md`](references/examples.md). The patterns below are the ones the skill flags most often.

### Semantics (WCAG 1.1.1, 4.1.2)

```dart
// WRONG: empty label, no label, ExcludeSemantics over actionable content removes the button
// from the semantics tree entirely, so the action is unreachable for screen reader users
Image.asset('assets/warning.png', semanticLabel: '')
Image.asset('assets/chart.png')
ExcludeSemantics(child: ElevatedButton(onPressed: _submit, child: const Text('Submit')))
```

```dart
// WRONG: Cupertino without semantic wrapper
CupertinoSwitch(value: _enabled, onChanged: _onChanged)
```

```dart
// WRONG: MergeSemantics around an interactive child folds the button's role away
MergeSemantics(
  child: Row(children: [const Text('Item'), IconButton(onPressed: _delete, icon: ...)]),
)
```

### Touch Targets and Dragging (WCAG 2.5.8, 2.5.7)

```dart
// WRONG: 16x16 target, below WCAG 2.2 2.5.8 AA (24 dp)
SizedBox(width: 16, height: 16, child: GestureDetector(onTap: _onTap, child: const Icon(Icons.close, size: 16)))
```

```dart
// WRONG: Dismissible with no non-drag alternative (WCAG 2.2 2.5.7)
Dismissible(key: ValueKey(item.id), onDismissed: (_) => _delete(item), child: ListTile(title: Text(item.name)))
```

### Focus (WCAG 2.1.1, 2.4.11)

```dart
// WRONG: GestureDetector is not keyboard-accessible
GestureDetector(onTap: _onTap, child: const Text('Click me'))
```

```dart
// WRONG: bottom bar covers focused TextField (WCAG 2.2 2.4.11)
Scaffold(
  resizeToAvoidBottomInset: false,
  bottomNavigationBar: const BottomAppBar(child: ...),
  body: ListView(children: [..., TextField(focusNode: _last), ...]),
)
```

### Text Scaling and Motion (WCAG 1.4.4, 2.3.3)

```dart
// WRONG: clips text at 1.5x font scale
SizedBox(height: 48, child: Text('Status: Ready'))
```

```dart
// WRONG: animation always plays
AnimatedContainer(duration: const Duration(milliseconds: 500), color: ..., child: child)
```

For corrected snippets, full classes (`AccessibleTapTarget`, `AccessibleSlider`, `AccessibleReorderableList`, `AccessiblePageRoute`, `AccessibleHero`), and the Cupertino semantic wrappers, see [`references/examples.md`](references/examples.md).

---

## Additional Resources

- [`references/wcag-criteria.md`](references/wcag-criteria.md) — per-level WCAG 2.2 criterion tables with the Flutter check for each.
- [`references/audit-templates.md`](references/audit-templates.md) — severity guide, report template, level-specific passed-check lists, cross-platform severity table.
- [`references/examples.md`](references/examples.md) — full Flutter widget classes per category, including all WCAG 2.2 patterns.
- [`references/widget-mapping.md`](references/widget-mapping.md) — widget-to-requirement quick reference for all commonly audited Flutter widgets.
- [`references/testing.md`](references/testing.md) — full accessibility test suite example across all seven audit categories.
- [`references/platforms/ios.md`](references/platforms/ios.md), [`android.md`](references/platforms/android.md), [`web.md`](references/platforms/web.md), [`macos.md`](references/platforms/macos.md), [`windows.md`](references/platforms/windows.md), [`linux.md`](references/platforms/linux.md) — per-platform WCAG 2.2 checks and Flutter-specific gotchas.

Official references:

- [WCAG 2.2 Recommendation](https://www.w3.org/TR/WCAG22/)
- [WCAG 2.2 Understanding Document](https://www.w3.org/WAI/WCAG22/Understanding/)
- [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility)
- [Flutter Web Semantics](https://docs.flutter.dev/platform-integration/web/accessibility)
- [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Material Design 3: Accessibility](https://m3.material.io/foundations/accessible-design/overview)
