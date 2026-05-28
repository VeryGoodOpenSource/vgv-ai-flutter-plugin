# Matchers Quick Reference

| Matcher | Asserts |
| --- | --- |
| `equals(x)` | Deep equality |
| `isA<T>()` | Value is of type `T` |
| `isA<T>().having(fn, name, matcher)` | Type check + property assertion |
| `isNull` / `isNotNull` | Null checks |
| `isTrue` / `isFalse` | Boolean checks |
| `contains(x)` | Collection or string contains `x` |
| `hasLength(n)` | Collection has `n` elements |
| `isEmpty` / `isNotEmpty` | Collection emptiness |
| `predicate<T>(fn)` | Custom boolean function |
| `closeTo(value, delta)` | Numeric value within `delta` of `value` |
| `greaterThan(n)` / `lessThan(n)` | Numeric comparisons |
| `containsAll(list)` | Collection contains all elements |
| `containsAllInOrder(list)` | Collection contains all elements in order |
| `throwsA(matcher)` | Function throws matching exception |
| `throwsA(isA<T>())` | Function throws exception of type `T` |
| `emits(matcher)` | Stream emits a matching value |
| `emitsInOrder(list)` | Stream emits values in order |
| `emitsDone` | Stream closes |
| `emitsError(matcher)` | Stream emits an error |
| `neverEmits(matcher)` | Stream never emits a matching value |
