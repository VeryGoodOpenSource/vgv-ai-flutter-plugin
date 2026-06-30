---
name: green-gate
description: >
  Drives a Dart or Flutter package to a fully green state through an autonomous
  verify-fix-rerun loop across four quality gates — analyze, format, test, and
  coverage. Exits only when a single final iteration proves all four pass with
  observed numbers.
when_to_use: >
  Use when the user wants a Dart or Flutter package driven to a fully passing
  state, or says things like "green gate", "make it green", "get this package
  passing", "get CI green", "fix all the analyze and test failures", "clean this
  package up before I open a PR", "bring coverage to 100", or "loop until
  everything passes". Prefer this over the single-gate testing or analysis
  skills when the request spans multiple gates or asks to fix and re-verify
  until clean.
argument-hint: "[directory]"
allowed-tools: Bash Read Glob Grep Edit Write mcp__dart__analyze_files mcp__dart__dart_format mcp__very-good-cli__test
model: sonnet
effort: medium
---

# Green Gate

Autonomous quality-gate loop for Dart and Flutter packages. Runs four gates —
analyze, format, test, coverage — reads real tool output, edits code and tests
to fix failures, and loops until one final iteration proves all four pass
simultaneously with observed numbers. Acts autonomously on objective failures;
escalates only on stalls, genuine ambiguity, or infrastructure failure.

This skill orchestrates tools and edits files. It defers the *how* of writing
tests to the `testing` skill — it never duplicates mocking, structure, or
coverage-pattern guidance.

---

## Core Standards

Apply these to ALL green-gate work:

- **Use MCP tools, never the Bash CLI, for gates** — analyze via
  `mcp__dart__analyze_files`, format via `mcp__dart__dart_format`, test and
  coverage via `mcp__very-good-cli__test`. The Bash test path
  (`very_good test`, `flutter test`, `dart test`) is hook-blocked by
  `block-cli-workarounds.sh`; `dart analyze` via Bash is redundant with the MCP
  tool. **Bash is reserved for parsing `coverage/lcov.info` only.**
- **Never cache green** — re-evaluate every gate every round. Fixing analyze or
  test failures and writing new test files shifts both formatting and the
  coverage denominator, so a previously green gate can regress.
- **Exit only on observed numbers** — the loop terminates only after a single
  final iteration in which analyze is clean, format reports zero changes, all
  tests pass, and `min_coverage` is satisfied, all observed in the same round.
  Declaring success from memory is forbidden; the success report carries the
  actual numbers from that final round.
- **Pass `coverage: true`, `min_coverage`, and `check_ignore: true` together** —
  omitting `coverage: true` silently produces no `lcov.info` (mimics a
  misconfiguration); omitting `check_ignore: true` makes the `// coverage:ignore`
  remedy a no-op.
- **Defer test-writing to the `testing` skill** — when a fix requires authoring
  tests, follow `skills/testing/SKILL.md` for structure, mocking, and naming.
- **Fix root causes, not symptoms** — never weaken a gate to pass it (do not
  delete failing assertions, lower the target to dodge work, or `// coverage:ignore`
  reachable code). Escalate genuine product/API decisions instead of guessing.
- **Act autonomously on objective failures** — analyzer errors, red tests, and
  coverage gaps are fixed without re-prompting. Escalate only per the matrix.

---

## The Loop

For each package root (see **Recursive / Monorepo**), run this algorithm:

1. **Discover** — resolve the package root (the `directory` argument or the
   workspace root); confirm a `pubspec.yaml` exists. Initialize loop state
   (iteration counter `0`, empty fingerprints, empty touched-files set).
2. **Analyze** — run `mcp__dart__analyze_files` with `applyFixes: true`. If any
   errors remain, this is the active gate. Fix, record the fingerprint, go to
   step 7.
3. **Format** — run `mcp__dart__dart_format` on the package root. It reformats
   the whole package in place. If it reports changed files, the gate is now
   green for the next round; if the tool is absent, see **Format Gate**.
4. **Test** — only if analyze is green this round. Run `mcp__very-good-cli__test`
   with the coverage parameters from **Test Gate**. If tests fail, fix, record
   the fingerprint, go to step 7.
5. **Coverage** — only if tests pass this round. The MCP `min_coverage` result is
   authoritative pass/fail. Parse `coverage/lcov.info` for the displayed
   percentage and per-file fix targets (advisory). If below target, author tests
   for the ranked under-covered files (via the `testing` skill), go to step 7.
6. **Exit** — if all four gates are green in *this same iteration*, emit the
   success report and stop. This is the only exit-green path.
7. **Re-verify** — increment the iteration counter, recompute the failure
   fingerprint, check escalation triggers (no progress, oscillation, cap). If a
   trigger fires, escalate; otherwise loop back to step 2 and re-evaluate **every**
   gate.

**One-pass no-op path** — invoked on an already-green package, iteration 1
finds analyze clean, format reporting zero changes, all tests passing, and
coverage at or above target. The loop emits the success report and exits without
editing a single file. A green package costs exactly one verify iteration.

---

## Loop State

State carried across iterations — without it, "no progress" is undecidable:

| State                                          | Purpose                                                                         |
| ---------------------------------------------- | ------------------------------------------------------------------------------- |
| **Iteration counter**                          | Enforce the cap (default 5, per package)                                        |
| **Per-gate failure fingerprint (prior round)** | Detect no-progress and oscillation                                              |
| **Files touched this round**                   | Distinguish a no-op round from a no-progress round; populate escalation reports |

Fingerprint keys per gate:

| Gate         | Fingerprint                                                  |
| ------------ | ------------------------------------------------------------ |
| **Analyze**  | Sorted set of `diagnosticCode @ file:line`                   |
| **Format**   | Set of files `dart format` would change (empty = green)      |
| **Test**     | Set of failing test IDs / names                              |
| **Coverage** | Observed percentage + sorted set of under-covered `SF` files |

Definitions:

- **No progress** — the current failure fingerprint is identical to the prior
  round's, or its failure count did not decrease. Escalate.
- **Oscillation** — the same two gates trade green/red across two consecutive
  rounds (e.g. a format fix re-breaks analyze, whose fix re-breaks format).
  Escalate.

---

## Gate Precedence

Fixed order: **analyze → format → test → coverage**. Two rules govern it:

1. **A downstream gate is not assessed until the upstream gate is green this
   round.** A red analyzer can make tests fail to compile; coverage is
   meaningless when tests do not pass — never parse `lcov.info` after a compile
   failure. Format runs after analyze so its reformatting does not churn over
   code that analyze's `applyFixes` is about to rewrite.
2. **Every gate is re-evaluated every round; green is never cached.** Exit
   requires all four green in the same final iteration.

---

## Analyze Gate

- Run `mcp__dart__analyze_files` with `applyFixes: true` so quick fixes are
  applied before diagnostics return. `roots` takes `[{ root: "file:///abs/path" }]`
  — a `file:` URI of the package root. There is **no recursive flag**; the skill
  enumerates package roots itself and passes each.
- The gate is green when zero **errors** remain. Treat error-severity diagnostics
  as blocking; address warnings and infos as well when they are within scope of
  the fix, but do not let an unrelated pre-existing info block the gate.
- **Hook interplay** — the PostToolUse `analyze.sh` hook fires on every
  Edit/Write and exits 2 (blocking) when a fix introduces a new analyze error.
  Treat that rejection as analyze-gate feedback in the same round, not a separate
  failure mode: the edit did not land, so revise it.

---

## Format Gate

- Run `mcp__dart__dart_format` on the package root each round. It runs
  `dart format .` over the **whole package** in place, so the gate is
  observation-based (it catches manual edits and pre-existing drift, not just
  files the loop edited) and self-fixing (one call leaves the package green; a
  second call reports zero changes).
- **Why format is a real gate, not just the hook** — the PostToolUse `format.sh`
  hook fires only on files the loop edits via Edit/Write. A hand-edited or
  pre-existing unformatted file the loop never touches would otherwise pass
  green-gate and then fail CI. The whole-package format closes that gap.
- **Availability caveat** — the dart MCP server requires Dart `3.9.0-163.0.dev`+,
  which is the floor for `analyze_files` too, so it is not format-specific.
  `dart_format` is a newer server tool than `analyze_files`, so some otherwise
  working server builds expose analyze but **not** format. Detect this by the
  tool being unavailable, not by SDK version.
- **Fallback when `mcp__dart__dart_format` is absent** — the `format.sh` hook
  still formats every file the loop edits. Document in the success report that
  untouched files are not covered in this mode, and surface it so the user can
  upgrade the dart MCP server / SDK to close the gap. **Do not** fall back to
  `dart format` via Bash — Bash stays reserved for lcov parsing.

---

## Test Gate

- Run `mcp__very-good-cli__test` with `coverage: true`, `min_coverage: <target>`,
  `check_ignore: true`, and the `exclude_coverage` glob (below).
- **Dart vs Flutter** — omit `dart` to let the tool auto-detect (Flutter is run
  when a Flutter project is detected). Pass `dart: true` only for a pure Dart
  package the tool would otherwise misclassify.
- **`directory`** — pass it when the package is not at the workspace root
  (monorepo sub-packages); omit it only when `pubspec.yaml` is at the root.
- **`timeout_seconds`** — always set a cap (e.g. `120`). Flutter tests hang
  indefinitely when `pumpAndSettle()` runs without a timeout; the cap kills the
  run instead of stalling the loop. A timeout kill is a tool failure, not a test
  failure — escalate it per the matrix.
- The gate is green when every test passes. A failing test is fixed
  autonomously unless it encodes a genuine product decision (escalate per the
  matrix).

---

## Coverage Gate

The MCP `min_coverage` result is **authoritative** for pass/fail. The
`coverage/lcov.info` parse is **advisory** — it supplies the displayed
percentage and per-file fix targets.

- **Default target is `100`** — VGV's house standard. The `very_good_cli`
  templates ship at 100% and Very Good Core's CI fails below it. "100%" means
  100% of *testable, hand-written* code: generated files leave the denominator
  via `exclude_coverage`, and `check_ignore: true` honors `// coverage:ignore`
  for genuinely unreachable lines, so the target is achievable rather than a
  ceiling on every generated line. The target is **overridable per invocation**
  (e.g. `80`) for legacy or non-template packages while the loop raises coverage
  toward it.
- **Default `exclude_coverage`** — `**/*.{g,freezed,gen}.dart` plus generated and
  l10n directories. This is one glob string (not a repeated flag); multiple
  patterns require brace expansion. If a CLI build does not honor brace
  expansion, fall back to the single most impactful glob `**/*.g.dart` and note
  the limitation in the report.
- **Advisory parse must mirror the gate** — the lcov parser applies the
  **identical exclusion set** used in `exclude_coverage`, or the displayed
  percentage will not match the authoritative gate. Read `SF` (source file),
  `LF` (lines found), `LH` (lines hit) per file; use `DA` (line, hit-count)
  records to point at specific uncovered lines.
- **`check_ignore` is Dart-only** — the MCP tool honors `// coverage:ignore`
  comments only when `dart: true`. For Flutter packages the ignore remedy may
  not be respected; prefer `exclude_coverage` for generated files and escalate
  genuinely unreachable Flutter lines rather than relying on the comment.

### Decision tree — a missing `lcov.info` has three distinct causes

| Cause                                                    | Detection                                    | Action                                                                          |
| -------------------------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------- |
| **(a) `coverage: true` not passed**                      | The skill's own tool call omitted the flag   | Fix the tool call and retry — **not** an escalation                             |
| **(b) Tests ran but produced no coverage** (all skipped) | MCP run succeeded, `lcov.info` missing/empty | Escalate as unprovable — surface to the user                                    |
| **(c) No test files exist**                              | No `test/` dir or zero `_test.dart` files    | Test gate **fails** — author tests via the `testing` skill; never treat as pass |

**Stale `lcov.info`** — trust `coverage/lcov.info` only when the MCP run reported
success **this round**. Delete it (or timestamp-check it) before each run so a
previous round's file is never read as current.

---

## Fixing

- **Fix only failing items** — address the diagnostics, tests, or under-covered
  files surfaced this round. Do not refactor unrelated code (YAGNI).
- **Coverage fixes = author tests** — for each ranked under-covered `SF` file,
  write tests following `skills/testing/SKILL.md`. Prioritize files by uncovered
  line count (`LF - LH`).
- **Bound files per round** — fix a coherent batch, then re-verify. Re-running
  the gates after each batch is what makes "no progress" detectable and prevents
  fixing one gate while silently breaking another.
- **Never weaken a gate** — no deleted assertions, no lowered target to dodge
  work, no `// coverage:ignore` on reachable code.

---

## Escalation

Stop and surface to the user when:

| Trigger                           | Detail                                                                                                                                                                                                                                                                                                                                              |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **No progress between rounds**    | Identical or non-decreasing failure fingerprint                                                                                                                                                                                                                                                                                                     |
| **Oscillation**                   | The same two gates trade green/red across two rounds                                                                                                                                                                                                                                                                                                |
| **Cap reached, gates still red**  | Terminal — report remaining failures per gate with their fingerprints                                                                                                                                                                                                                                                                               |
| **Real-bug red test**             | A failure that looks like a genuine product decision rather than a coding mistake                                                                                                                                                                                                                                                                   |
| **Ambiguous fix**                 | Multiple valid resolutions (e.g. change the API vs suppress the lint) — prefer root-cause; escalate when it is a product/API decision                                                                                                                                                                                                               |
| **Unreachable-code coverage gap** | Suggest `// coverage:ignore` (requires `check_ignore: true`, Dart-only) rather than chasing 100%                                                                                                                                                                                                                                                    |
| **Denominator hygiene**           | A generated file not matched by the exclude glob — widen `exclude_coverage`, not `// coverage:ignore`                                                                                                                                                                                                                                               |
| **Tool / hook failure**           | MCP test timeout (`timeout_seconds` kill), analyzer crash, CLI-missing hook denial (escalate with the install hint `dart pub global activate very_good_cli`), or a *repeated* `analyze.sh` rejection that still blocks a needed edit after revision — a single rejection is in-loop analyze-gate feedback (see **Analyze Gate**), not an escalation |

When escalating, report the active gate, its current fingerprint, the files
touched, the iteration count, and the specific decision the user must make.

---

## Recursive / Monorepo

- **All packages must pass** — continue on failure (fix every failing package),
  then emit an aggregate report. One package's red gate does not abort the others.
- **Per-package iteration budget** — the cap of 5 is per package, not global, so
  a 12-package monorepo does not exhaust a global budget on package one.
- **Shared package-root discovery** — walk for `pubspec.yaml` files. The
  `analyze_files` `roots` set must match the package set
  `mcp__very-good-cli__test --recursive` (`recursive: true`) covers.
- **lcov path is `<package>/coverage/lcov.info`** — resolved per discovered root.
- **Single `min_coverage` applies to all packages** — documented limitation: the
  tool schema has no per-package coverage override. State the shared target in
  the aggregate report.

---

## Success Report

Emit this only after the final iteration proved every gate green in the same
round. Fill in observed numbers — never placeholders, never values recalled from
an earlier round:

```markdown
## Green Gate: PASS — <package>

- Analyze:    0 errors (mcp__dart__analyze_files)
- Format:     clean — 0 files changed (mcp__dart__dart_format)
- Tests:      <N> passed, 0 failed (mcp__very-good-cli__test)
- Coverage:   <observed>% >= <target>% (min_coverage gate; lcov.info parsed)
- Iterations: <n>/<cap>
```

For a monorepo, emit one block per package plus a one-line aggregate
(`<P>/<P> packages green`). When the format fallback was used (no
`mcp__dart__dart_format`), append a note that only loop-edited files were
formatted and recommend upgrading the dart MCP server / SDK.

---

## Additional Resources

- [`skills/testing/SKILL.md`](../testing/SKILL.md) — how to write Dart unit,
  Flutter widget, and golden tests (structure, `mocktail` mocking, naming).
- [`skills/testing/references/coverage.md`](../testing/references/coverage.md) —
  coverage-driven test patterns (`copyWith`, branches, error paths) for closing
  per-file gaps.
- `hooks/scripts/block-cli-workarounds.sh` — why the Bash test path is blocked
  and gates use MCP tools.
