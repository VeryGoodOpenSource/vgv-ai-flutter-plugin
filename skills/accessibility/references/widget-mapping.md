# Accessibility — Widget-to-Accessibility Requirements Mapping

Quick-reference table mapping Flutter widgets to their accessibility requirements and recommended implementations.

---

## Widget-to-Accessibility Requirements Mapping

| Widget | Accessibility Requirement | Implementation |
| --- | --- | --- |
| `Image` | Text alternative | `semanticLabel` or `Semantics(label:)`; use `excludeFromSemantics: true` for decorative images |
| `Icon` | Text alternative | Wrap in `Semantics(label:)` or use within a widget that provides a label |
| `IconButton` | Text alternative + touch target | `tooltip` parameter (auto-provides semantic label); inherits 48dp minimum |
| `GestureDetector` | Keyboard access | Replace with `InkWell` or button widget; `GestureDetector` is pointer-only |
| `InkWell` | Semantic role | Add `Semantics(label:, button: true)` when used as a custom button |
| `ElevatedButton` | Touch target | Inherits 48dp minimum; provide descriptive `child` text |
| `TextButton` | Touch target | Inherits 48dp minimum; provide descriptive `child` text |
| `TextField` | Label | Use `InputDecoration(labelText:)` — always provide a visible label |
| `Checkbox` | Label + state | Wrap in `CheckboxListTile` for automatic label association |
| `Switch` | Label + state | Wrap in `SwitchListTile` for automatic label association |
| `Slider` | Label + value | Use `Semantics(label:, value:)` or `Slider.adaptive` |
| `DropdownButton` | Label + expanded state | Wrap in `DropdownButtonFormField` with `InputDecoration(labelText:)` |
| `AlertDialog` | Focus management | `showDialog` handles focus trapping and restoration automatically |
| `BottomSheet` | Focus management | `showModalBottomSheet` handles focus trapping and restoration automatically |
| `ListView` | Scrolling semantics | Flutter handles scroll semantics automatically; ensure list items are accessible |
| `TabBar` | Tab semantics | Flutter provides tab semantics automatically via `TabBar` + `TabBarView` |
| `AnimatedContainer` | Motion sensitivity | Gate `duration` on `MediaQuery.of(context).disableAnimations` |
| `Hero` | Motion sensitivity | Skip `Hero` when `disableAnimations` is true |
| `PageRoute` | Motion sensitivity | Override `buildTransitions` to return `child` directly when animations disabled |

---

## References

- [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility) — official Flutter documentation on accessibility APIs, TalkBack/VoiceOver integration, and `Semantics` widget usage
- [WCAG 2.1 Understanding Document](https://www.w3.org/WAI/WCAG21/Understanding/) — W3C explanations of each success criterion, including intent, examples, and sufficient techniques
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/) — filterable checklist of all success criteria by level
