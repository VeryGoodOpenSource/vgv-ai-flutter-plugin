---
title: "Accessibility"
description: "Audit or remediate Flutter widgets against WCAG 2.2 accessibility conformance levels A, AA, or AAA across iOS, Android, Web, macOS, Windows, and Linux."
---
<!-- GENERATED FROM skills/accessibility/SKILL.md — DO NOT EDIT. Run `npm run gen:docs` after editing the skill. -->

Flutter accessibility auditing and remediation across WCAG 2.2 conformance levels A, AA, and AAA. The skill is split into a workflow (this file) plus reference files loaded on demand:

- [Accessibility — Audit Report Templates](/best-practices/accessibility/audit-templates) — severity guide, report template, level-specific passed-check lists for A, AA, AA + selected AAA, and AAA. Also includes cross-platform severity adjustment table.
- [Accessibility — Extended Examples](/best-practices/accessibility/examples) — extended Flutter code per category, including WCAG 2.2 patterns (focus-not-obscured, dragging alternatives, Cupertino semantic wrappers, MergeSemantics correctness).
- [Accessibility — iOS Platform Reference](/best-practices/accessibility/platforms/ios), [Accessibility — Android Platform Reference](/best-practices/accessibility/platforms/android), [Accessibility — Web Platform Reference](/best-practices/accessibility/platforms/web), [Accessibility — macOS Platform Reference](/best-practices/accessibility/platforms/macos), [Accessibility — Windows Platform Reference](/best-practices/accessibility/platforms/windows), [Accessibility — Linux Platform Reference](/best-practices/accessibility/platforms/linux) — per-platform WCAG 2.2 checks. Load only the file(s) matching the selected platform(s).

Read whichever reference file matches the current phase. Do not duplicate its content here.

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

**Exclude Semantics** (WCAG 1.1.1) — Never use `ExcludeSemantics` on non-decorative content.

**Text Containers** (WCAG 1.4.4) — Fixed-height containers must not wrap `Text`. Use `minHeight` constraints. Fixed heights clip text at 1.5x font scale on Android, sooner on iOS where Larger Accessibility Sizes go to ~3.1x.

**Contrast** (WCAG 1.4.3) — All text and UI components must meet the contrast ratio for the selected WCAG level. See the WCAG Level Criteria Reference section below.

**Cupertino Semantics** (WCAG 4.1.2) — Cupertino widgets (`CupertinoSwitch`, `CupertinoSlider`, `CupertinoSegmentedControl`, `CupertinoButton`) ship with weaker semantic defaults than their Material equivalents. Always wrap them in `Semantics(label:, value:, button:)`.

**Autofill Hints** (WCAG 1.3.5) — Every `TextField` collecting structured personal data (email, username, password, name, address, phone, oneTimeCode) must declare `autofillHints`. Required for 1.3.5 at AA and the foundation for 3.3.7 Redundant Entry at A.

**Async Announcements** (WCAG 4.1.3) — Every async user-visible state change must announce itself via `Semantics(liveRegion: true)` or `SemanticsService.announce`.

---

## Workflow

Every accessibility engagement follows four phases in sequence. Do not skip Phase 1 or Phase 2.

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

For each finding, capture: file path and approximate line number, WCAG criterion ID + name + version (2.0 / 2.1 / 2.2), platform(s) affected, severity (CRITICAL / MAJOR / MINOR), current behavior, expected behavior, Flutter fix as a before-and-after diff.

**Outcome:** After completing all seven categories, produce the Audit Report using the template in [Accessibility — Audit Report Templates](/best-practices/accessibility/audit-templates). Pick the level-specific passed-check list that matches Phase 1.

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

---

## WCAG 2.2 Level Criteria Reference

Level AA includes all Level A criteria. Level AAA includes all Level A and AA criteria. The "Version" column flags whether the criterion is from WCAG 2.0, 2.1, or 2.2. WCAG 2.2 removed 4.1.1 Parsing.

### Level A

| WCAG ID | Version | Criterion | Flutter Check |
| --- | --- | --- | --- |
| 1.1.1 | 2.0 | Non-text Content | `semanticLabel` on images, `Semantics(label:)` on icons, `excludeFromSemantics: true` on decorative |
| 1.3.1 | 2.0 | Info and Relationships | Semantic roles. `MergeSemantics` for grouped label/value pairs only, never around interactive children |
| 1.3.2 | 2.0 | Meaningful Sequence | Reading order matches visual order. `FocusTraversalGroup` + `OrderedTraversalPolicy` |
| 1.3.3 | 2.0 | Sensory Characteristics | Instructions do not rely solely on shape, size, location, or sound |
| 1.4.1 | 2.0 | Use of Color | Color never sole differentiator |
| 2.1.1 | 2.0 | Keyboard | All functionality via keyboard or switch access. No bare `GestureDetector` |
| 2.1.2 | 2.0 | No Keyboard Trap | Focus can always be moved away |
| 2.3.1 | 2.0 | Three Flashes or Below Threshold | No content flashes > 3 times per second |
| 2.4.1 | 2.0 | Bypass Blocks | Skip-navigation mechanism. **Web only** |
| 2.4.2 | 2.0 | Page Titled | Each screen has a meaningful title. **Web: `<title>` tag** |
| 2.4.3 | 2.0 | Focus Order | Tab/focus order preserves meaning |
| 2.5.3 | 2.1 | Label in Name | Visible label text contained in accessible name |
| 3.2.6 | 2.2 | Consistent Help | Help mechanism in same relative order across screens |
| 3.3.1 | 2.0 | Error Identification | Form errors identified in text, not color alone |
| 3.3.2 | 2.0 | Labels or Instructions | All form fields have visible labels |
| 3.3.7 | 2.2 | Redundant Entry | Multi-step forms must not re-collect already-provided info unless re-entry is essential |
| 4.1.2 | 2.0 | Name, Role, Value | `Semantics(label:, button: true)`, `Tooltip`, state via `checked`, `selected`, `enabled` |
| 4.1.3 | 2.1 | Status Messages | `Semantics(liveRegion: true)`, `SemanticsService.announce()` |

### Level AA (adds these to Level A)

| WCAG ID | Version | Criterion | Flutter Check |
| --- | --- | --- | --- |
| 1.3.4 | 2.1 | Orientation | App not locked to single orientation without essential reason |
| 1.3.5 | 2.1 | Identify Input Purpose | Correct `keyboardType` and `autofillHints` |
| 1.4.3 | 2.0 | Contrast (Minimum) | Normal text 4.5:1, large text 3:1 |
| 1.4.4 | 2.0 | Resize Text | Text scales to 200% (300% on iOS) without loss |
| 1.4.5 | 2.0 | Images of Text | Use `Text`, not images of text |
| 1.4.10 | 2.1 | Reflow | Content reflows at 320 CSS px equivalent |
| 1.4.11 | 2.1 | Non-text Contrast | UI components and focus indicators 3:1 |
| 1.4.12 | 2.1 | Text Spacing | Content not lost under increased spacing |
| 1.4.13 | 2.1 | Content on Hover or Focus | Dismissable, hoverable, persistent. **Web/desktop** |
| 2.4.5 | 2.0 | Multiple Ways | More than one way to locate a screen |
| 2.4.6 | 2.0 | Headings and Labels | Descriptive. `Semantics(header: true)` for sections |
| 2.4.7 | 2.0 | Focus Visible | Keyboard focus indicator always visible |
| 2.4.11 | 2.2 | Focus Not Obscured (Minimum) | Focused component not entirely hidden by author-created content |
| 2.5.7 | 2.2 | Dragging Movements | Every drag has a single-pointer alternative |
| 2.5.8 | 2.2 | Target Size (Minimum) | Targets >= 24x24 CSS px, with documented exceptions |
| 3.1.2 | 2.0 | Language of Parts | **Web: `lang` attribute** |
| 3.2.3 | 2.0 | Consistent Navigation | Consistent across screens |
| 3.2.4 | 2.0 | Consistent Identification | Same-function components identified consistently |
| 3.3.3 | 2.0 | Error Suggestion | Suggested correction when possible |
| 3.3.4 | 2.0 | Error Prevention (Legal/Financial) | Reversible or confirmable |
| 3.3.8 | 2.2 | Accessible Authentication (Minimum) | No required cognitive function test without alternative. Allow paste, support password managers, no puzzle CAPTCHAs without alternative |

### Level AAA (adds these to A and AA)

| WCAG ID | Version | Criterion | Flutter Check |
| --- | --- | --- | --- |
| 1.4.6 | 2.0 | Contrast (Enhanced) | Normal 7:1, large 4.5:1 |
| 2.1.3 | 2.0 | Keyboard (No Exception) | No `GestureDetector` anywhere |
| 2.2.3 | 2.0 | No Timing | No time limits except real-time events |
| 2.2.6 | 2.1 | Timeouts | Inactivity warning |
| 2.3.2 | 2.0 | Three Flashes | Zero flashing |
| 2.3.3 | 2.1 | Animation from Interactions | Every animation gated on `disableAnimations` |
| 2.4.8 | 2.0 | Location | Users always know where they are |
| 2.4.9 | 2.0 | Link Purpose (Link Only) | Understandable from link text alone |
| 2.4.12 | 2.2 | Focus Not Obscured (Enhanced) | No occlusion at all, not just total occlusion |
| 2.4.13 | 2.2 | Focus Appearance | At least 2 CSS px perimeter, encloses component, 3:1 against unfocused |
| 2.5.5 | 2.1 | Target Size (Enhanced) | Targets >= 44x44 CSS px |
| 2.5.6 | 2.1 | Concurrent Input Mechanisms | No single-modality restriction |
| 3.2.5 | 2.0 | Change on Request | Context changes only on user request |
| 3.3.5 | 2.0 | Help | Context-sensitive help available |
| 3.3.6 | 2.0 | Error Prevention (All) | All submissions reversible or confirmable |
| 3.3.9 | 2.2 | Accessible Authentication (Enhanced) | No cognitive function test even with alternative |

---

## Quick Anti-Pattern Reference

Full code samples and corrected versions live in [Accessibility — Extended Examples](/best-practices/accessibility/examples). The patterns below are the ones the skill flags most often.

### Semantics (WCAG 1.1.1, 4.1.2)

```dart
// WRONG: empty label, no label, ExcludeSemantics over actionable
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

For corrected snippets, full classes (`AccessibleTapTarget`, `AccessibleSlider`, `AccessibleReorderableList`, `AccessiblePageRoute`, `AccessibleHero`), and the Cupertino semantic wrappers, see [Accessibility — Extended Examples](/best-practices/accessibility/examples).

---

## Additional Resources

- [Accessibility — Audit Report Templates](/best-practices/accessibility/audit-templates) — severity guide, report template, level-specific passed-check lists, cross-platform severity table.
- [Accessibility — Extended Examples](/best-practices/accessibility/examples) — full Flutter widget classes per category, including all WCAG 2.2 patterns.
- [Accessibility — iOS Platform Reference](/best-practices/accessibility/platforms/ios), [Accessibility — Android Platform Reference](/best-practices/accessibility/platforms/android), [Accessibility — Web Platform Reference](/best-practices/accessibility/platforms/web), [Accessibility — macOS Platform Reference](/best-practices/accessibility/platforms/macos), [Accessibility — Windows Platform Reference](/best-practices/accessibility/platforms/windows), [Accessibility — Linux Platform Reference](/best-practices/accessibility/platforms/linux) — per-platform WCAG 2.2 checks and Flutter-specific gotchas.

Official references:

- [WCAG 2.2 Recommendation](https://www.w3.org/TR/WCAG22/)
- [WCAG 2.2 Understanding Document](https://www.w3.org/WAI/WCAG22/Understanding/)
- [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility)
- [Flutter Web Semantics](https://docs.flutter.dev/platform-integration/web/accessibility)
- [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Material Design 3: Accessibility](https://m3.material.io/foundations/accessible-design/overview)
