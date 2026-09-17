# green-gate eval notes

## Grading

Graded on narration, not on the artifact. No MCP server is available to these runs and the
fixture has no source in `lib/` or `test/`, so the loop this skill exists to run cannot
execute here. The cases grade the decisions the skill narrates: which tool it says it
would call for each gate, the arguments it would pass, the order it would run them in,
what it refuses to weaken, and when it stops and escalates. Never assert that a response
*called* a tool — unsatisfiable here, and it measures the harness. Mocking the MCP servers
in the native harness is a separate, later piece of work, and none of these cases assume
it.

Every prompt therefore ends by asking for a plan or a verdict rather than for a run, and
every scenario is stated in the prompt rather than left on disk. A prompt that says "fix
my package" earns "there is no code here" and every grader then fails for an unrelated
reason. Prompts describing a repo also say outright that it is not on disk; without that
the model spends its answer on "lib/ only has a .gitkeep".

Routing is the dominant failure mode here. On a full run 4 of 6 positive cases missed
routing, and every one of those was a prompt asking *about* the gates rather than for a
run. The cause was legible: on `green-gate-plans-the-four-gates-in-order` the model named
the skill in its own answer ("this is what the green-gate skill automates end to end. Want
me to invoke it?") and then improvised a `flutter analyze` / `flutter test --coverage`
shell plan, because the skill read as a runner and the prompt said not to run anything.
The skill's `description` now claims gate *configuration* questions too, and Core
Standards carries a plan-only directive.

Two things are deliberately absent:

- No Dart-parse grader. No case demands Dart code, so no case has fenced dart blocks to
  parse.
- No negative check on `flutter test`. The skill teaches *why* that command is
  hook-blocked, so a correct answer often names it in order to reject it. The tool-routing
  rule is graded by the MCP tool names instead.

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### green-gate-plans-the-four-gates-in-order

**Discriminates.** Unrouted, the bare model improvises a `flutter analyze` / `flutter test
--coverage` shell plan and puts format before analyze.

**Grader notes.** `names-analyze-files` exists because the analyze gate goes through the
Dart MCP server, not `dart analyze` in Bash. `names-check-ignore` and `names-min-coverage`
are the coverage triple with `applyFixes`; `check_ignore` is the one a bare model never
produces, and omitting it makes the `// coverage:ignore` remedy a silent no-op.

### green-gate-refuses-to-weaken-the-coverage-gate

**Discriminates.** Without the skill the model is agreeable — it drops the threshold to
90, adds the ignore comment, and declares the package clean.

### green-gate-refuses-to-carry-green-forward

**Discriminates.** The rules are "Never cache green" and "exit only on observed numbers":
all four gates re-run in one final round, and the format gate is judged by changed count.
Without the skill the model takes the user's word for the earlier analyze and format
results, checks coverage only, and declares green.

**Grader notes.** `format-judged-by-changed-count` covers the format gate's own trap: the
format tool reports success whether or not it rewrote anything, so the changed count is
the only signal it is green.

### green-gate-excludes-generated-files-instead-of-ignoring-them

**Discriminates.** Without the skill the model endorses the teammate's ignore comments and
suggests settling at a 95–97% target.

**Grader notes.** `exclude_coverage` is the skill's parameter name, not general Dart
knowledge.

**Grader notes.** Two cases here have moved between 2/3 and 3/3 across runs with no skill
change at all. That band is this suite's noise floor, so a single red rep is not evidence:
resist "fixing" green-gate itself off one.

### green-gate-escalates-when-the-loop-stops-making-progress

**Discriminates.** The no-progress trigger has three parts: an unchanged failure
fingerprint stops the loop, a standing "keep retrying" instruction does not override it,
and the escalation report carries per-failure detail plus a decision ask. Without the
skill the model accepts the blanket permission and keeps grinding, or stops with a bare
"4 errors remain" and no decision ask.

**Grader notes.** `names-the-no-progress-trigger` matches the skill's own term for the
comparison that makes "no progress" decidable.

### green-gate-budgets-per-package-across-a-monorepo

**Discriminates.** The monorepo rules are a per-package iteration budget,
continue-on-failure with a per-package report, one shared `min_coverage` with no
per-package override, and pubspec.yaml-walk discovery shared by analyze and test. Without
the skill the model gives a generic "run the tests in each package" plan, invents a
per-package coverage override for the 62% package, and aborts on the first red one.

### green-gate-stays-out-of-plain-function-work

**Discriminates.** Nothing else catches the skill firing where it should not. Must NOT
appear: the skill's parameter vocabulary (`min_coverage`, `exclude_coverage`,
`check_ignore`, `analyze_files`, `lcov`), the phrase "quality gate", a verify-fix-rerun
loop, coverage targets, or the four-gate sequence.

**Grader notes.** Task success is graded mechanically by `answers-the-question`, not by
the judge. The judge never sees the prompt, so "is the merge logic right" is unanswerable
from the output alone.
