# Accessibility — Audit Report Templates

Audit report templates by WCAG 2.1 conformance level, including severity guide and passed-checks checklists for levels A, AA, and AAA.

---

## Audit Report Templates by Level

Each template is pre-annotated with the criteria applicable at that level. Use the template matching the level selected in Phase 1 of the Workflow.

### Severity Guide

| Severity | Meaning |
| --- | --- |
| **CRITICAL** | Blocks assistive technology users entirely — fix before merging |
| **MAJOR** | Significant barrier — fix in current sprint |
| **MINOR** | Degraded experience or polish item — schedule for next sprint |

Severity assignment:

- **CRITICAL** — criterion applies at selected level AND issue completely blocks the use case (e.g., no semantic label on primary action, `GestureDetector` on a required flow, zero focus visibility)
- **MAJOR** — criterion applies at selected level AND issue significantly degrades the experience (e.g., contrast ratio fails by > 1 point, touch target < 40dp, dialog does not trap focus)
- **MINOR** — criterion applies at selected level AND issue is a refinement (e.g., contrast fails marginally, live region missing on non-critical status, focus indicator present but border width 1px instead of 2px)

### Template (all levels)

```text
# Flutter Accessibility Audit

**Date:** YYYY-MM-DD
**WCAG Level:** [A | AA | AAA]
**Platforms:** [Mobile | Desktop | Web | combination]
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
- **WCAG:** [criterion ID] [criterion name] (Level [A/AA/AAA])
- **Platform(s):** [Mobile | Desktop | Web | All]
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
```

### Passed Checks — Level A

```text
- [x] A · Semantics & Screen Reader — all images/icons have semantic labels; roles correct
- [x] B · Touch Target Sizes — all interactive elements >= 48dp (mobile)
- [x] C · Focus & Keyboard — all interactions reachable via keyboard; no traps
- [x] D · Color — color is never sole differentiator
- [x] E · Text Scaling — no fixed-height text containers
- [x] F · Animation & Motion — no content flashes > 3 Hz (2.3.1)
```

### Passed Checks — Level AA (Level A + these)

```text
- [x] C · Focus & Keyboard — focus indicator visible with 3:1 contrast (2.4.7, 2.4.11)
- [x] D · Color Contrast — normal text >= 4.5:1, large text >= 3:1, UI components >= 3:1 (1.4.3, 1.4.11)
- [x] E · Text Scaling — text scales to 200% without loss (1.4.4)
- [x] F · Animation & Motion — all animations gated on disableAnimations (2.3.3)
- [x] G · Orientation — not locked to single orientation (1.3.4)
- [x] H · Input Purpose — autofillHints and keyboardType correct (1.3.5)
- [x] I · Reflow — content reflows at 320px equivalent (1.4.10) [web/desktop]
```

### Passed Checks — Level AAA (Level AA + these)

```text
- [x] B · Touch Target Sizes — all interactive elements >= 44dp (2.5.5)
- [x] C · Focus & Keyboard — no GestureDetector anywhere (2.1.3); indicator encloses component with 2px border (2.4.12)
- [x] D · Color Contrast (Enhanced) — normal text >= 7:1, large text >= 4.5:1 (1.4.6)
- [x] F · Animation & Motion — zero flashing content (2.3.2)
- [x] J · No Timing — no mandatory time limits (2.2.3)
- [x] K · Location — breadcrumbs or current-screen indication visible (2.4.8)
- [x] L · Input Modality — no single-modality restriction (2.5.6)
```
