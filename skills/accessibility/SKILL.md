---
name: vgv-accessibility
description: Flutter accessibility auditing and remediation with WCAG 2.1 level selection (A, AA, AAA) across mobile, desktop, and web platforms. Begins by asking the WCAG conformance level and target platform(s) before applying level-appropriate, platform-aware criteria.
when_to_use: Use when building, auditing, or reviewing widgets for screen reader support, touch targets, focus management, color contrast, text scaling, or motion sensitivity.
argument-hint: "[wcag-level] [platform]"
allowed-tools: Read Glob Grep
effort: high
---

# Accessibility

Flutter accessibility auditing and remediation across WCAG 2.1 conformance levels A, AA, and AAA — semantics, touch targets, focus management, color contrast, text scaling, and motion sensitivity across mobile, desktop, and web platforms.

---

## Core Standards

Apply these standards to ALL accessibility work:

- **Begin every audit by asking the user which WCAG 2.1 conformance level they are targeting (A, AA, or AAA)** — never assume AA
- **Begin every audit by asking which platforms are targeted (mobile, desktop, web)** — screen reader behavior and keyboard requirements differ per platform
- **Every `Image` must have `semanticLabel` or be wrapped in `Semantics(label:)`** — decorative images use `excludeFromSemantics: true`
- **Never use `GestureDetector` for tap targets** — use `InkWell`, `ElevatedButton`, `TextButton`, or `IconButton`; `GestureDetector` is pointer-only and unreachable via keyboard or switch access
- **All interactive elements: 48x48 dp minimum touch target** — enforce with `SizedBox`, `ConstrainedBox`, or `padding`
- **Never use color as the sole differentiator** — always pair color with a label, icon, or shape
- **All animations must respect `MediaQuery.disableAnimations`** — gate every `AnimationController`, `AnimatedContainer`, and `Hero` transition on this flag
- **Icon-only buttons must have `Tooltip` or `Semantics(label:)`** — screen readers have no other way to convey purpose
- **Never use `ExcludeSemantics` on non-decorative content** — doing so hides meaningful information from assistive technology
- **Fixed-height containers must not wrap `Text`** — use `minHeight` constraints; fixed heights clip text at 1.5-2x font scale
- **All text and UI components must meet the contrast ratio for the selected WCAG level** — see the WCAG Level Criteria Reference section below for level-specific thresholds

---

## Workflow

Every accessibility engagement follows four phases in sequence. Do not skip Phase 1 or Phase 2.

### Phase 1 — Conformance Level Selection

Before auditing or writing any accessibility code, ask:

> "Which WCAG 2.1 conformance level are you targeting?
>
> - **A** — Removes the most critical barriers. Covers alt text, keyboard access, no seizure risks, basic structure, and error identification.
> - **AA** — Builds on Level A. Adds contrast ratios (4.5:1 / 3:1), captions, resize text, focus appearance, and consistent navigation. This is the most common legal and compliance standard.
> - **AAA** — Highest level. Adds enhanced contrast (7:1), sign language, extended audio descriptions, and no timing requirements. Full AAA is rarely required for entire products but may apply to specific components.
>
> Reply with A, AA, or AAA."

Record the selected level. All subsequent audit checks, report criteria references, and fix recommendations apply only the rules for that level (plus all levels below it).

### Phase 2 — Platform Selection

Ask:

> "Which platform(s) is this app targeting? Select all that apply:
>
> - **Mobile** — iOS (VoiceOver) and/or Android (TalkBack)
> - **Desktop** — macOS (VoiceOver), Windows (Narrator, NVDA, JAWS), Linux (Orca)
> - **Web** — browser-based; NVDA+Chrome (Windows), JAWS+Chrome (Windows), VoiceOver+Safari (macOS)
>
> Reply with one or more: Mobile, Desktop, Web."

Record selected platforms. Apply platform-specific checks during the audit:

- **Mobile** — touch target sizes (48x48 dp), TalkBack/VoiceOver semantic traversal order, gesture alternatives for all pointer-only interactions
- **Desktop** — full keyboard navigation required for every interaction, focus indicators always visible, no touch-only interactions
- **Web** — bypass blocks (2.4.1), page titles (2.4.2), language of page (3.1.1), reflow at 320px equivalent (1.4.10), hover/focus content persistence (1.4.13)

### Phase 3 — Level-Appropriate Audit

Audit the provided files or widgets across the following six categories, checking only criteria applicable to the selected level AND relevant to the selected platforms. For each finding, capture: file path and approximate line number, WCAG criterion ID and name, platform(s) affected, current behavior, expected behavior, Flutter fix (before/after code).

Audit categories (check all six in order):

1. **Semantics & Screen Reader** — labels, roles, live regions, merge/exclude semantics. Screen readers by platform: TalkBack (Android), VoiceOver (iOS/macOS), Narrator/NVDA/JAWS (Windows), Orca (Linux)
2. **Touch Target Sizes** — 48x48 dp minimum for all interactive elements (mobile-critical); on desktop/web, verify keyboard focus area is visible and sufficient
3. **Focus & Keyboard Navigation** — keyboard operability, traversal order, dialog focus trapping, focus indicators; critical for desktop and web; verify gesture fallbacks exist on mobile
4. **Color Contrast** — text and UI component ratios at the selected level's threshold (see the WCAG Level Criteria Reference section below)
5. **Text Scaling** — no fixed-height text containers, no clamped text scaling, overflow handling at 200% scale
6. **Animation & Motion** — `disableAnimations` gating on all `AnimationController`, `Hero`, and `AnimatedContainer` instances; no content flashing > 3 Hz

After completing all six categories, produce the Audit Report using the level-specific template in [references/audit-templates.md](references/audit-templates.md).

### Phase 4 — Remediation Scope Selection

After delivering the report, use the `AskUserQuestion` tool with a single question:

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

Apply exactly the fixes the user selects. After applying fixes, confirm: "Fixed [N] findings ([severities]). [N remaining] remain open."

---

## WCAG Level Criteria Reference

Use this table during Phase 3 to determine which criteria apply at the selected level. Level AA includes all Level A criteria. Level AAA includes all Level A and AA criteria.

### Level A — Core Criteria

| WCAG ID | Criterion | Flutter Check |
| --- | --- | --- |
| 1.1.1 | Non-text Content | `semanticLabel` on images; `Semantics(label:)` on icons; `excludeFromSemantics: true` on decorative |
| 1.3.1 | Info and Relationships | Semantic roles: `button`, `header`, `link`, `checked`; `MergeSemantics` for grouped content |
| 1.3.2 | Meaningful Sequence | Reading order matches visual order; `FocusTraversalGroup` with `OrderedTraversalPolicy` |
| 1.3.3 | Sensory Characteristics | Instructions do not rely solely on shape, size, visual location, or sound |
| 1.4.1 | Use of Color | Color never sole differentiator — always pair with icon, label, or pattern |
| 2.1.1 | Keyboard | All functionality via keyboard/switch access; no bare `GestureDetector` |
| 2.1.2 | No Keyboard Trap | Focus can always be moved away; standard Flutter overlay widgets handle this |
| 2.3.1 | Three Flashes or Below Threshold | No content flashes > 3 times/second |
| 2.4.1 | Bypass Blocks | Skip navigation mechanism for repeated blocks — **web platform only** |
| 2.4.2 | Page Titled | Each screen has a meaningful title in semantics — **web platform: `<title>` tag** |
| 2.4.3 | Focus Order | Tab/focus order preserves meaning; `FocusTraversalOrder` with `NumericFocusOrder` |
| 2.5.3 | Label in Name | Visible label text is contained in the accessible name |
| 3.3.1 | Error Identification | Form errors identified in text, not color alone |
| 3.3.2 | Labels or Instructions | All form fields have visible labels; `InputDecoration(labelText:)` |
| 4.1.2 | Name, Role, Value | `Semantics(label:, button: true)`, `Tooltip`; state exposed via `checked`, `selected`, `enabled` flags |
| 4.1.3 | Status Messages | `Semantics(liveRegion: true)`, `SemanticsService.announce()` for async status |

### Level AA — Additional Criteria (includes all Level A)

| WCAG ID | Criterion | Flutter Check |
| --- | --- | --- |
| 1.3.4 | Orientation | App does not lock to single orientation without essential reason; remove `SystemChrome.setPreferredOrientations` locks |
| 1.3.5 | Identify Input Purpose | Text fields use correct `keyboardType` and `autofillHints` |
| 1.4.3 | Contrast (Minimum) | Normal text 4.5:1; large text 3:1 against background |
| 1.4.4 | Resize Text | Text scales to 200% without loss of content or functionality; no fixed-height text containers, no `TextScaler.noScaling` |
| 1.4.5 | Images of Text | Do not use images of text for styled text — use `Text` widget |
| 1.4.10 | Reflow | Content reflows at 320 CSS px equivalent without horizontal scroll — use `Flexible`, `Wrap`, `SingleChildScrollView` |
| 1.4.11 | Non-text Contrast | UI components and focus indicators have at least 3:1 contrast |
| 1.4.12 | Text Spacing | Content not lost when letter/word/line spacing increased; avoid `overflow: TextOverflow.clip` in fixed containers |
| 1.4.13 | Content on Hover or Focus | Hoverable/focusable content is dismissable, hoverable, and persistent — **web/desktop: hover tooltips and menus** |
| 2.4.5 | Multiple Ways | More than one way to locate a screen (search, navigation, sitemap) |
| 2.4.6 | Headings and Labels | Headings and labels are descriptive; `Semantics(header: true)` for section headings |
| 2.4.7 | Focus Visible | Keyboard focus indicator is always visible |
| 2.4.11 | Focus Appearance (Minimum) | Focus indicator has 3:1 contrast and minimum 2px outline — **desktop/web priority** |
| 3.1.2 | Language of Parts | Language changes in content are programmatically identified — **web platform: `lang` attribute** |
| 3.2.3 | Consistent Navigation | Navigation is consistent across screens |
| 3.2.4 | Consistent Identification | Components with same function identified consistently |
| 3.3.3 | Error Suggestion | When input error is detected, correction is suggested if possible |
| 3.3.4 | Error Prevention | Submissions with legal/financial data are reversible or confirmable |

### Level AAA — Additional Criteria (includes all Level A and AA)

| WCAG ID | Criterion | Flutter Check |
| --- | --- | --- |
| 1.4.6 | Contrast (Enhanced) | Normal text 7:1; large text 4.5:1 against background |
| 2.1.3 | Keyboard (No Exception) | All functionality via keyboard with no exceptions — no `GestureDetector` anywhere |
| 2.2.3 | No Timing | No time limits except for real-time events |
| 2.2.6 | Timeouts | Users warned of inactivity timeouts |
| 2.3.2 | Three Flashes | No content flashes at all — zero tolerance, not just below threshold |
| 2.3.3 | Animation from Interactions | All motion animation can be disabled — gate every `AnimationController`, `Hero`, `AnimatedContainer` on `disableAnimations` |
| 2.4.8 | Location | Users always know where they are within the app |
| 2.4.9 | Link Purpose (Link Only) | Link purpose understandable from link text alone |
| 2.4.12 | Focus Appearance (Enhanced) | Focus indicator: at least 2px, encloses the component, 3:1 contrast against adjacent colors |
| 2.5.5 | Target Size (Enhanced) | Touch targets at least 44x44 dp (AAA raises practical minimum from 48dp recommendation) |
| 2.5.6 | Concurrent Input Mechanisms | App does not restrict input to a single modality |
| 3.2.5 | Change on Request | Context changes only initiated by user request |
| 3.3.5 | Help | Context-sensitive help is available |
| 3.3.6 | Error Prevention (All) | All submissions are reversible or confirmable |

---

## Semantics & Screen Reader

Flutter's `Semantics` widget communicates widget purpose to screen readers (TalkBack on Android, VoiceOver on iOS and macOS, Narrator/NVDA/JAWS on Windows, Orca on Linux).

**Anti-patterns — missing or wrong semantic labels:**

```dart
// WRONG — Empty semanticLabel on meaningful content
Image.asset('assets/warning_icon.png', semanticLabel: '') // announces nothing

// WRONG — No semanticLabel on informative image
Image.asset('assets/chart.png') // screen reader skips or announces filename
```

**Anti-pattern — excluding meaningful content:**

```dart
// WRONG — Hides actionable content from assistive technology
ExcludeSemantics(
  child: ElevatedButton(onPressed: _submit, child: const Text('Submit')),
)
```

**Live regions** — dynamic content that updates without interaction must announce changes:

```dart
Semantics(liveRegion: true, child: Text('$itemCount items in cart'))
SemanticsService.announce('Upload complete', TextDirection.ltr);
```

---

## Touch Target Sizes

All interactive elements must have a minimum touch target of 48x48 dp (WCAG 2.5.5).

**Anti-pattern — touch target too small:**

```dart
// WRONG — Touch target is 24x24, below 48dp minimum
SizedBox(
  width: 24,
  height: 24,
  child: GestureDetector(
    onTap: _onTap,
    child: const Icon(Icons.close, size: 24),
  ),
)
```

Use `SizedBox(width: 48, height: 48)`, `ConstrainedBox(minWidth: 48, minHeight: 48)`, or `Padding(padding: EdgeInsets.all(12))` around small icons.

---

## Focus & Keyboard Navigation

Every interactive widget must be reachable via keyboard and switch access (WCAG 2.1.1, 2.1.2). Use `FocusTraversalGroup` + `OrderedTraversalPolicy` when the default tab order does not match the visual reading order. `showDialog` and `showModalBottomSheet` handle focus trapping and restoration automatically.

**Anti-pattern — keyboard-inaccessible tap handler:**

```dart
// WRONG — GestureDetector is not keyboard-accessible
GestureDetector(onTap: _onTap, child: const Text('Click me'))

// CORRECT — InkWell is focusable and keyboard-accessible
InkWell(onTap: _onTap, child: const Text('Click me'))
```

Custom focus indicators must meet 3:1 contrast (WCAG 2.4.11 AA); at AAA (2.4.12), indicator must be ≥ 2px and enclose the component.

---

## Color Contrast

Contrast requirements start at Level AA — Level A has no contrast requirement.

| Element | Level AA | Level AAA | WCAG criterion |
| --- | --- | --- | --- |
| Normal text (< 18pt / < 14pt bold) | 4.5:1 | 7:1 | 1.4.3 / 1.4.6 |
| Large text (>= 18pt / >= 14pt bold) | 3:1 | 4.5:1 | 1.4.3 / 1.4.6 |
| UI components and focus indicators | 3:1 | 3:1 | 1.4.11 |

Use `Theme.of(context).colorScheme` tokens for consistent contrast.

**Anti-patterns:**

```dart
// WRONG — Light gray on white fails 4.5:1
Text('Status: Active', style: TextStyle(color: Colors.grey.shade300))

// WRONG — Color as sole differentiator
Container(color: isValid ? Colors.green : Colors.red) // no label or icon
```

---

## Text Scaling

Widgets must accommodate user font-size preferences up to 2x scale without clipping (WCAG 1.4.4).

**Anti-pattern — fixed height around text:**

```dart
// WRONG — Fixed height clips text at large scale
SizedBox(height: 48, child: Text('This text will be clipped at 1.5x font scale'))
```

**Anti-pattern — clamping text scale:**

```dart
// WRONG — Overrides user accessibility preferences
MediaQuery(
  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
  child: const Text('Ignoring user font preferences'),
)
```

Use `ConstrainedBox(constraints: BoxConstraints(minHeight: 48))` around text containers.

---

## Animation & Motion

All animations must respect `MediaQuery.disableAnimations` (WCAG 2.3.3). No content may flash > 3 Hz (WCAG 2.3.1).

**Anti-pattern — ignoring reduced-motion preference:**

```dart
// WRONG — Animation always plays regardless of user preference
AnimatedContainer(
  duration: const Duration(milliseconds: 500),
  color: _isActive ? Colors.blue : Colors.grey,
  child: child,
)

// CORRECT — Gate on disableAnimations
AnimatedContainer(
  duration: MediaQuery.of(context).disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 500),
  color: _isActive ? Colors.blue : Colors.grey,
  child: child,
)
```

---

## Additional Resources

- [Extended code examples](references/examples.md) — full widget classes per category (`AccessibleRatingBar`, `AccessiblePageRoute`, etc.)
- [Audit report templates](references/audit-templates.md) — level-specific templates (A, AA, AAA) with pre-annotated passed checks
- [Full accessibility test suite](references/testing.md) — `tester.ensureSemantics()` patterns covering all six categories
- [Widget-to-accessibility mapping](references/widget-mapping.md) — quick-reference table of Flutter widgets and their accessibility requirements

Official references:

- [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility)
- [WCAG 2.1 Understanding Document](https://www.w3.org/WAI/WCAG21/Understanding/)
