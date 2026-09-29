# Upgrade very_good_analysis — Reference

Extended examples and common lint rule fixes for the very_good_analysis upgrade skill.

---

## Common Lint Rule Fixes

| Lint rule                   | Typical fix                                          | Behavior risk                                        |
| --------------------------- | ---------------------------------------------------- | ---------------------------------------------------- |
| `prefer_const_constructors` | Add `const` keyword                                  | None — style only                                    |
| `use_super_parameters`      | Convert `super.param` to initializer                 | None — style only                                    |
| `unnecessary_late`          | Remove `late` from immediately-initialized variables | None — style only                                    |
| `avoid_dynamic_calls`       | Cast the receiver to a specific type                 | Yes — the cast throws where the dynamic call did not |
| `require_trailing_commas`   | Add trailing comma in argument/parameter lists       | None — style only                                    |
| `unnecessary_null_checks`   | Remove redundant `!` operators                       | None — style only                                    |

Fix the style-only rules in the upgrade PR. A fix carrying behavior risk does not go in
silently: name the risk and hand the decision to a human, per the "Avoid behavior changes"
core standard. `avoid_dynamic_calls` is the usual one — `map['total'] as double` throws a
`TypeError` on a JSON integer that `map['total'].toStringAsFixed(2)` handled, so the cast
is a code change wearing a lint's clothes and belongs in its own reviewed PR.

---

## very_good_analysis 11.0.0 — Dart 3.13 constructor lints

`very_good_analysis` 11.0.0 follows `very_good_core` 1.6.0 onto Dart 3.13 and enables four new
constructor rules. All four are style-only (no behavior risk), but each only has a valid fix once
the package targets Dart 3.13 or newer — below that SDK, leave the classic form and raise any SDK
bump as its own change.

- `use_declaring_parameters` — a constructor taking initializing formals (`this.field`) plus
  matching `final` fields should instead use primary-constructor **declaring parameters**. This is
  the rule that flags most existing widget, model, event, and state code.
- `unnecessary_type_name_in_constructor` — inside a primary constructor body, refer to the instance
  with `this` rather than by repeating the class name.
- `unnecessary_primary_constructor_body` — drop an empty `{}` body on a primary constructor and end
  the header with `;`.
- `empty_container_bodies` — replace an empty `{}` body (class, mixin, or extension type) with `;`.

The `use_declaring_parameters` fix moves the fields into the class header. `const` sits between
`class` and the class name:

```dart
// Before — flagged by use_declaring_parameters on Dart 3.13+
class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) => Text(userId);
}

// After — primary constructor with a declaring parameter
class const ProfileCard({required final String userId, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(userId);
}
```

`use_declaring_parameters` can touch a large share of a codebase — every widget, model, event, and
state constructor is a candidate — but it is a new warning the bump introduced, so it belongs in
the upgrade PR. Apply it only when the package already targets Dart 3.13; if the bump also forces
an SDK-constraint change, that belongs in its own PR.
