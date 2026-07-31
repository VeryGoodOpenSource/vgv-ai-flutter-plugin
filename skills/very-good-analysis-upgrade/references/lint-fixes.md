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
