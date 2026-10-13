# Coverage Gate — Details

Companion to the **Coverage Gate** section of `green-gate/SKILL.md`. The MCP
`min_coverage` result is **authoritative** for pass/fail, and with
`show_uncovered: true` its `Lines not covered:` block is the per-file fix-target
list. Everything below about `coverage/lcov.info` is the **fallback** path, for a
result that carries no such block.

## Default target

`100` is VGV's house standard — the `very_good_cli` templates ship at 100% and
Very Good Core's CI fails below it. "100%" means 100% of _testable, hand-written_
code: generated files leave the denominator via `exclude_coverage`, and
`check_ignore: true` honors `// coverage:ignore` for genuinely unreachable lines,
so the target is achievable rather than a ceiling on every generated line. It is
**overridable per invocation** (e.g. `80`) for legacy or non-template packages
while the loop raises coverage toward it.

## show_uncovered

Pass `show_uncovered: true` on every `mcp__very-good-cli__test` call. The result
then names every uncovered line per file — the same granularity the loop would
otherwise reconstruct from lcov:

```text
Expected coverage >= 100.00% but actual is 33.33%.
Lines not covered:
  - lib/src/weather_repository.dart: 4, 5
```

- It applies to **both Dart and Flutter** runs, unlike `check_ignore`.
- The block honors `exclude_coverage`, so it already mirrors the authoritative
  gate — no exclusion set to re-apply by hand.
- It appears whenever lines are uncovered: inside the `min_coverage` failure when
  the gate is red, and as informational output when the gate passes with lines
  still uncovered. A clean 100% run prints no block, which is not a fallback
  trigger.
- It arrived in `very_good_cli` 1.5.0, the plugin's minimum. A `test` tool schema
  without the parameter means an older CLI — use the lcov fallback.

## exclude_coverage

Default: `**/*.{g,freezed,gen}.dart` plus generated and l10n directories. This is
one glob string (not a repeated flag); multiple patterns require brace expansion.
If a CLI build does not honor brace expansion, fall back to the single most
impactful glob `**/*.g.dart` and note the limitation in the report.

## Fallback parse must mirror the gate

When parsing lcov, apply the **identical exclusion set** used in
`exclude_coverage`, or the displayed percentage will not match the authoritative
gate. Read `SF` (source file), `LF` (lines found), `LH` (lines hit) per file; use
`DA` (line, hit-count) records to point at specific uncovered lines.

## check_ignore is Dart-only

The MCP tool honors `// coverage:ignore` comments only when `dart: true`. For
Flutter packages the ignore remedy may not be respected; prefer
`exclude_coverage` for generated files and escalate genuinely unreachable Flutter
lines rather than relying on the comment.

## Decision tree — a missing lcov.info has three distinct causes

| Cause                                                    | Detection                                    | Action                                                                          |
| -------------------------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------- |
| **(a) `coverage: true` not passed**                      | The skill's own tool call omitted the flag   | Fix the tool call and retry — **not** an escalation                             |
| **(b) Tests ran but produced no coverage** (all skipped) | MCP run succeeded, `lcov.info` missing/empty | Escalate as unprovable — surface to the user                                    |
| **(c) No test files exist**                              | No `test/` dir or zero `_test.dart` files    | Test gate **fails** — author tests via the `testing` skill; never treat as pass |

## Stale lcov.info

Trust `coverage/lcov.info` only when the MCP run reported success **this round**.
Delete it (or timestamp-check it) before each run so a previous round's file is
never read as current.
