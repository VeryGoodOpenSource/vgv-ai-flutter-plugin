# WCAG 2.2 Level Criteria Reference

Level AA includes all Level A criteria. Level AAA includes all Level A and AA criteria. The "Version" column flags whether the criterion is from WCAG 2.0, 2.1, or 2.2. WCAG 2.2 removed 4.1.1 Parsing.

## Level A

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

## Level AA (adds these to Level A)

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

## Level AAA (adds these to A and AA)

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
