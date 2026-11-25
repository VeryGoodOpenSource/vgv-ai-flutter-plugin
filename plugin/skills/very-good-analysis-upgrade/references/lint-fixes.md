# Upgrade very_good_analysis — Reference

Extended examples and common lint rule fixes for the very_good_analysis upgrade skill.

---

## Common Lint Rule Fixes

| Lint rule                               | Typical fix                                          | Behavior risk                                        |
| --------------------------------------- | ---------------------------------------------------- | ---------------------------------------------------- |
| `prefer_const_constructors`             | Add `const` keyword                                  | None — style only                                    |
| `use_super_parameters`                  | Convert `super.param` to initializer                 | None — style only                                    |
| `unnecessary_late`                      | Remove `late` from immediately-initialized variables | None — style only                                    |
| `avoid_dynamic_calls`                   | Cast the receiver to a specific type                 | Yes — the cast throws where the dynamic call did not |
| `require_trailing_commas`               | Add trailing comma in argument/parameter lists       | None — style only                                    |
| `unnecessary_null_checks`               | Remove redundant `!` operators                       | None — style only                                    |
| `async_return_with_no_await`            | Add `await`, or drop `async` and return the `Future` | Yes — changes which `catch` sees the error           |
| `initialize_in_field_declaration`       | Move the initializer to the field declaration        | None — style only                                    |
| `unnecessary_const_in_enum_constructor` | Remove `const` from the enum constructor             | None — style only                                    |

Fix the style-only rules in the upgrade PR. A fix carrying behavior risk does not go in
silently: name the risk and hand the decision to a human, per the "Avoid behavior changes"
core standard. `avoid_dynamic_calls` is the usual one — `map['total'] as double` throws a
`TypeError` on a JSON integer that `map['total'].toStringAsFixed(2)` handled, so the cast
is a code change wearing a lint's clothes and belongs in its own reviewed PR.

---

## very_good_analysis 11.0.0 — Dart 3.13 lints

`very_good_analysis` 11.0.0 requires Dart 3.13 (`sdk: ^3.13.0`) and enables seven new rules. Three
are in the table above: `async_return_with_no_await`, `initialize_in_field_declaration` and
`unnecessary_const_in_enum_constructor`. The other four are style-only. Three target constructors
and one, `empty_container_bodies`, targets empty bodies in classes, enums, mixins and extensions. A
package below Dart 3.13 cannot resolve 11.0.0 at all. That SDK bump is its own PR, so report the
conflict and stop.

11.0.0 also sets `formatter: trailing_commas: automate`. After the bump, `dart format` adds and
removes trailing commas across the package. That diff is forced by the bump, so it belongs in the
upgrade PR. Put it in its own commit so reviewers can skip it.

- `unnecessary_type_name_in_constructor` — a class-body constructor that repeats the class name
  (`const ProfileCard(...)`) should name the unnamed constructor `new` instead. **This is the rule
  that flags most existing widget, model, event, and state code**, and its minimal fix is one word:
  rename `ProfileCard(...)` to `new(...)`. It does not force a primary constructor on anyone.
- `use_declaring_parameters` — inside a **primary constructor**, a parameter written as an
  initializing formal (`this.field`) should instead be a declaring parameter (`final Type field`).
  It only fires once the class already uses a primary-constructor header, so it never touches a
  classic class-body constructor.
- `unnecessary_primary_constructor_body` — drop an empty `{}` body on a primary constructor and end
  the header with `;`.
- `empty_container_bodies` — replace an empty `{}` body (class, enum, mixin, or extension) with `;`.

The minimal fix for `unnecessary_type_name_in_constructor` leaves the class shape untouched — it
only renames the unnamed constructor to `new`:

```dart
// Before — flagged by unnecessary_type_name_in_constructor on Dart 3.13+
class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) => Text(userId);
}

// Minimal fix — name the unnamed constructor `new`
class ProfileCard extends StatelessWidget {
  const new({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) => Text(userId);
}
```

To modernize further, promote the fields to primary-constructor **declaring parameters**. `const`
sits between `class` and the class name, and the inheritance clause follows the parameter list.
This form clears both rules at once and is what the widget, model, event, and state skills show on
the Dart 3.13 baseline:

```dart
// Modernized — a primary constructor with a declaring parameter
class const ProfileCard({required final String userId, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(userId);
}
```

`unnecessary_type_name_in_constructor` can touch a large share of a codebase — every unnamed
class-body constructor is a candidate — but it is a new warning the bump introduced, so it belongs
in the upgrade PR. Promoting to declaring parameters is a further modernization, not a forced fix;
`new` alone satisfies the lint.
