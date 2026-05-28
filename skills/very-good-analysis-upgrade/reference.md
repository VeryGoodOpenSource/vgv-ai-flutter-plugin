# Upgrade very_good_analysis — Reference

Extended examples and common lint rule fixes for the very_good_analysis upgrade skill.

---

## Common Lint Rule Fixes

| Lint rule                   | Typical fix                                          |
| --------------------------- | ---------------------------------------------------- |
| `prefer_const_constructors` | Add `const` keyword                                  |
| `use_super_parameters`      | Convert `super.param` to initializer                 |
| `unnecessary_late`          | Remove `late` from immediately-initialized variables |
| `avoid_dynamic_calls`       | Cast the receiver to a specific type                 |
| `require_trailing_commas`   | Add trailing comma in argument/parameter lists       |
| `unnecessary_null_checks`   | Remove redundant `!` operators                       |
